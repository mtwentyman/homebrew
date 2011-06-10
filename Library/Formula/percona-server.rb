require 'formula'

class PerconaServer < Formula
  url 'http://www.percona.com/redir/downloads/Percona-Server-5.5' +
      '/Percona-Server-5.5.11-20.2/source/Percona-Server-5.5.11-rel20.2.tar.gz'
  homepage 'http://www.percona.com/software/percona-server/'
  md5      '2ce38bb65dcb64f0b8febb98ef054fae'
  version  '5.5.11-rel20.2'

  depends_on 'cmake' => :build
  depends_on 'readline'
  depends_on 'pidof'

  fails_with_llvm "https://github.com/mxcl/homebrew/issues/issue/144"

  skip_clean :all # So "INSTALL PLUGIN" can work.

  def plist
    'com.percona.mysqld.plist'
  end

  def options
    [
      ['--with-tests', 'To enable unit testing at build, we need to download the unit testing suite'],
      ['--with-embedded', 'Build the embedded server'],
      ['--enable-local-infile', 'Build with local infile, loading support']
    ]
  end

  def install
    # Make sure the var/msql directory exists
    (var+"mysql").mkpath

    args = [".",
            "-DCMAKE_INSTALL_PREFIX=#{prefix}",
            "-DMYSQL_DATADIR=#{var}/mysql",
            "-DINSTALL_MANDIR=#{man}",
            "-DINSTALL_DOCDIR=#{doc}",
            "-DINSTALL_INFODIR=#{info}",
            # CMake prepends prefix, so use share.basename
            "-DINSTALL_MYSQLSHAREDIR=#{share.basename}/#{name}",
            "-DWITH_SSL=yes",
            "-DDEFAULT_CHARSET=utf8",
            "-DDEFAULT_COLLATION=utf8_general_ci",
            "-DSYSCONFDIR=#{etc}"]

    if ARGV.include? '--with-tests' # To enable unit testing at build, we need
                                    # to download the unit testing suite
      args << "-DENABLE_DOWNLOADS=ON"
    else
      args << "-DWITH_UNIT_TESTS=OFF"
    end

    if ARGV.include? '--with-embedded' # Build the embedded server
      args << "-DWITH_EMBEDDED_SERVER=ON"
    end

    if ARGV.build_universal? # Make universal for binding to
                             # universal applications
      args << "-DCMAKE_OSX_ARCHITECTURES='i386;x86_64'"
    end

    if ARGV.include? '--enable-local-infile' # Build with local infile
                                             # loading support
      args << "-DENABLED_LOCAL_INFILE=1"
    end

    system "cmake", *args
    system "make"
    system "make install"

    (prefix+plist).write startup_plist

    # Don't create databases inside of the prefix!
    # See: https://github.com/mxcl/homebrew/issues/4975
    rm_rf prefix + 'data'

    # Link the setup script into bin
    ln_s prefix + 'scripts/mysql_install_db', bin + 'mysql_install_db'
    # Fix up the control script and link into bin
    inreplace "#{prefix}/support-files/mysql.server" do |s|
      s.gsub!(/^(PATH=".*)(")/, "\\1:#{HOMEBREW_PREFIX}/bin\\2")
    end
    ln_s "#{prefix}/support-files/mysql.server", bin
  end

  def caveats; <<-EOS.undent
    Set up databases to run AS YOUR USER ACCOUNT with:
        unset TMPDIR
        mysql_install_db --verbose --user=`whoami` --basedir="$(brew --prefix mysql)" --datadir=#{var}/mysql --tmpdir=/tmp

    To set up base tables in another folder, or use a differnet user to run
    mysqld, view the help for mysqld_install_db:
        mysql_install_db --help

    and view the MySQL documentation:
      * http://dev.mysql.com/doc/refman/5.5/en/mysql-install-db.html
      * http://dev.mysql.com/doc/refman/5.5/en/default-privileges.html

    To run as, for instance, user "mysql", you may need to `sudo`:
        sudo mysql_install_db ...options...

    Start mysqld manually with:
        mysql.server start

        Note: if this fails, you probably forgot to run the first two steps up above

    A "/etc/my.cnf" from another install may interfere with a Homebrew-built
    server starting up correctly.

    To connect:
        mysql -uroot

    To launch on startup:
    * if this is your first install:
        mkdir -p ~/Library/LaunchAgents
        cp #{prefix}/#{plist} ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/#{plist}

    * if this is an upgrade and you already have the #{plist} loaded:
        launchctl unload -w ~/Library/LaunchAgents/#{plist}
        cp #{prefix}/#{plist} ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/#{plist}

    You may also need to edit the plist to use the correct "UserName".

    EOS
  end

  def startup_plist; <<-EOPLIST.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist.gsub(/\.plist/, '')}</string>
      <key>Program</key>
      <string>#{bin}/mysqld_safe</string>
      <key>RunAtLoad</key>
      <true/>
      <key>UserName</key>
      <string>#{`whoami`.chomp}</string>
      <key>WorkingDirectory</key>
      <string>#{var}</string>
    </dict>
    </plist>
    EOPLIST
  end
end