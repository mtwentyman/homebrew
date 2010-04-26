require 'formula'

class GearmanPhpExtension <Formula
  url 'http://pecl.php.net/get/gearman-0.7.0.tgz'
  homepage 'http://gearman.org/'
  md5 '2e1da4a3d5e3c1e103b772da92f37680'

  depends_on 'libevent'
  depends_on 'gearman'
  depends_on 'autoconf'
  aka 'gearman-ext'

  def install
    # system "cp -R . ass"
    system "mv gearman-0.7.0/* ./"
    system "phpize"
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
