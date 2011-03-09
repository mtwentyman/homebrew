require 'formula'

def mysql_installed?
    `which mysql_config`.length > 0
end

class Php <Formula
  url 'http://www.php.net/get/php-5.3.5.tar.gz/from/this/mirror'
  homepage 'http://php.net/'
  md5 'fb727a3ac72bf0ce37e1a20468a7bb81'
  version '5.3.5'

  # So PHP extensions don't report missing symbols
  skip_clean ['bin', 'sbin']

  depends_on 'freetype'
  depends_on 'gettext'
  depends_on 'jpeg'
  depends_on 'libpng'
  depends_on 'libxml2'
  depends_on 'mcrypt'
  depends_on 'libiconv'
  depends_on 'readline' if ARGV.include? '--with-readline'

  if ARGV.include? '--with-mysql'
    depends_on 'mysql' => :recommended unless mysql_installed?
  end
  if ARGV.include? '--with-fpm'
    depends_on 'libevent'
  end
  
  def options
   [
     ['--with-apache', 'Build shared Apache 2.0 Handler module'],
     ['--with-fpm', 'Enable building of the fpm SAPI executable'],
     ['--with-libedit', 'Building with libedit cli support'],
     ['--with-mysql', 'Build with MySQL support'],
     ['--with-readline', 'Building with readline cli support.']
   ]
  end

  def patches
   DATA
  end
  
  def configure_args
    args = [
      "--prefix=#{prefix}",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--with-config-file-path=#{prefix}/etc",
      "--with-iconv-dir=/usr",
      "--enable-bcmath",
      "--enable-calendar",
      "--enable-exif",
      "--enable-ftp",
      "--enable-gd-native-ttf",
      "--enable-mbstring",
      "--enable-mbregex",
      "--enable-memcache",
      "--enable-memory-limit",
      "--enable-mbstring",
      "--enable-pcntl",
      "--enable-shmop",
      "--enable-soap",
      "--enable-sockets",
      "--enable-sqlite-utf8",
      "--enable-sysvsem",
      "--enable-sysvshm",
      "--enable-sysvmsg",
      "--enable-wddx",
      "--enable-zip",
      "--with-bz2=/usr",
      "--with-curl=/usr",
      "--with-gettext=#{Formula.factory('gettext').prefix}",
      "--with-gd",
      "--with-iodbc",
      "--with-jpeg-dir=#{Formula.factory('jpeg').prefix}",
      "--with-kerberos=/usr",
      "--with-ldap",
      "--with-ldap-sasl=/usr",
      "--with-libxml-dir=#{Formula.factory('libxml2').prefix || '/usr'}",
      "--with-mcrypt=#{Formula.factory('mcrypt').prefix}",
      "--with-openssl=/usr",
      "--with-png-dir=#{Formula.factory('libpng').prefix}",
      "--with-tidy",
      "--with-xmlrpc",
      "--with-xsl=/usr",
      "--with-zlib=/usr",
      "--without-pear",
      "--mandir=#{man}"
    ]

    # Bail if both php-fpm and apxs are enabled
    # http://bugs.php.net/bug.php?id=52419
    if (ARGV.include? '--with-fpm') && (ARGV.include? '--with-apache')
      onoe "You can only enable PHP FPM or Apache, not both"
      puts "For more information:"
      puts "http://bugs.php.net/bug.php?id=52419"
      exit 99
    end

    # Enable PHP FPM
    if ARGV.include? '--with-fpm'
      args.push "--enable-fpm"
    end

    # Build Apache module
    if ARGV.include? '--with-apache'
      args.push "--with-apxs2=/usr/sbin/apxs"
      args.push "--libexecdir=#{prefix}/libexec"
    end

    if ARGV.include? '--with-mysql'
      if mysql_installed?
        args.push "--with-mysql-sock=/tmp/mysql.sock"
        args.push "--with-mysqli=mysqlnd"
        args.push "--with-mysql=mysqlnd"
        args.push "--with-pdo-mysql=mysqlnd"
      else
        args.push "--with-mysqli=#{Formula.factory('mysql').bin}/mysql_config}"
        args.push "--with-mysql=#{Formula.factory('mysql').prefix}"
        args.push "--with-pdo-mysql=#{Formula.factory('mysql').prefix}"
      end
    end

    if ARGV.include? '--with-libedit'
      args.push('--with-libedit')
    else
      puts 'Not building libedit cli support. Pass --with-libedit if needed.'
    end

    if ARGV.include? '--with-readline'
      args.push "--with-readline=#{HOMEBREW_PREFIX}/Cellar/readline/#{versions_of("readline").first}"
    else
      puts 'Not building readline cli support. Pass --with-readline if needed.'
    end

    return args
  end
  
  def install
    ENV.O3 # Speed things up
    system "./configure", *configure_args

    if ARGV.include? '--with-apache'
      # Use Homebrew prefix for the Apache libexec folder
      inreplace "Makefile",
        "INSTALL_IT = $(mkinstalldirs) '$(INSTALL_ROOT)/usr/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='$(INSTALL_ROOT)/usr/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so",
        "INSTALL_IT = $(mkinstalldirs) '#{prefix}/libexec/apache2' && $(mkinstalldirs) '$(INSTALL_ROOT)/private/etc/apache2' && /usr/sbin/apxs -S LIBEXECDIR='#{prefix}/libexec/apache2' -S SYSCONFDIR='$(INSTALL_ROOT)/private/etc/apache2' -i -a -n php5 libs/libphp5.so"
    end
    
    system "make"
    system "make install"

    system "cp ./php.ini-production #{prefix}/etc/php.ini"
  end

  def caveats; <<-EOS
    For 10.5 and Apache:
      Apache needs to run in 32-bit mode. You can either force Apache to start 
      in 32-bit mode or you can thin the Apache executable.
   
    To enable PHP in Apache add the following to httpd.conf and restart Apache:
      LoadModule php5_module    #{prefix}/libexec/apache2/libphp5.so

    The php.ini file can be found in:
      #{prefix}/etc/php.ini
EOS
  end
end

__END__
diff -Naur php-5.3.2/ext/tidy/tidy.c php/ext/tidy/tidy.c 
--- php-5.3.2/ext/tidy/tidy.c	2010-02-12 04:36:40.000000000 +1100
+++ php/ext/tidy/tidy.c	2010-05-23 19:49:47.000000000 +1000
@@ -22,6 +22,8 @@
 #include "config.h"
 #endif
 
+#include "tidy.h"
+
 #include "php.h"
 #include "php_tidy.h"
 
@@ -31,7 +33,6 @@
 #include "ext/standard/info.h"
 #include "safe_mode.h"
 
-#include "tidy.h"
 #include "buffio.h"
 
 /* compatibility with older versions of libtidy */
