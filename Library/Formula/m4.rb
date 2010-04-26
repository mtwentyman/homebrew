require 'formula'

class M4 <Formula
  url 'http://ftp.gnu.org/gnu/m4/m4-1.4.14.tar.gz'
  homepage 'http://www.gnu.org/software/m4/'
  md5 'f0542d58f94c7d0ce0d01224e447be66'

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
