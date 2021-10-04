# How to install Janus on Ubuntu 20.04:

## Dependencies

```sh
sudo apt-get install libmicrohttpd-dev libjansson-dev libnice-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev libopus-dev libogg-dev libini-config-dev libcollection-dev libwebsockets-dev pkg-config gengetopt automake libtool doxygen graphviz git cmake
```

### Build libsrtp

```sh
wget https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz
tar xfv v2.2.0.tar.gz
cd libsrtp-2.2.0
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install
```

## Build

```sh
git clone git://github.com/meetecho/janus-gateway.git

cd janus-gateway

sh autogen.sh

./configure --disable-websockets --disable-rabbitmq --disable-docs --prefix=/opt/janus

make && sudo make install
sudo make configs
```

## Config

In streaming plugin jcfg (find in /opt/janus/etc/, I think), this should be the only streaming setup
```
ft-audio: {
	type = "rtp"
	id = 1
	description = "Footron Audio"
	audio = true
	audioport = 5002
	audiopt = 111
	audiortpmap = "opus/48000/2"
}
```

## GStreamer setup

Find default monitor source: `pacmd list-sources | grep -e "*\|name:"` (find first index with asterisk before it, name below it is inside angle brackets)

```sh
gst-launch-1.0 pulsesrc device=$DEFAULT_DEVICE ! audioresample ! opusenc bitrate=20000 ! rtpopuspay ! udpsink host=0.0.0.0 port=5002
```

Where `$DEFAULT_DEVICE` is the name of the device you found in the last step.

## Run

There are some issues with certificates, but we need to figure out how to convince Janus to either use LetsEncrypt to come up with its own or not use certificates at all—in this case, we don't _really_ care if the audio is broadcast in the open.

I think the problem with certificates comes down to permission on the snakeoil certificate in /etc/ssh/private. But my guess is it's a bad idea to make it visible to everyone, so while that seems to work, we should find out what the "right" solution is—maybe we just use certbot?

This link might have some insight: https://webrtc.ventures/2021/08/hardened-janus-gateway/

```
/opt/janus/bin/janus
```
