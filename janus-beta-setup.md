# How to install Janus on Ubuntu 20.04:

## Dependencies

```sh
sudo apt-get install libmicrohttpd-dev libjansson-dev libnice-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libini-config-dev libcollection-dev libwebsockets-dev pkg-config gengetopt automake libtool doxygen graphviz git cmake
```

### Build libsrtp

```
wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz
tar xfv v2.2.0.tar.gz
cd libsrtp-2.2.0
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install
```

## Build

```
git clone git://github.com/meetecho/janus-gateway.git

cd janus-gateway

sh autogen.sh

./configure --disable-websockets --disable-rabbitmq --disable-docs --prefix=/opt/janus

make && sudo make install
sudo make configs
```

## Run

There are some issues with certificates, but we need to figure out how to convince Janus to either use LetsEncrypt to come up with its own or not use certificates at all—in this case, we don't _really_ care if the audio is broadcast in the open.

I think the problem with certificates comes down to permission on the snakeoil certificate in /etc/ssh/private. But my guess is it's a bad idea to make it visible to everyone, so while that seems to work, we should find out what the "right" solution is—maybe we just use certbot?

This link might have some insight: https://webrtc.ventures/2021/08/hardened-janus-gateway/

```
/opt/janus/bin/janus
```
