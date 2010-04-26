require 'formula'

class Autoconf <Formula
  url 'http://ftp.gnu.org/gnu/autoconf/autoconf-2.65.tar.gz'
  homepage 'http://www.gnu.org/software/autoconf/'
  md5 '46cfb40e0babf4c64f8325f03da81c9b'

  depends_on 'm4'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
