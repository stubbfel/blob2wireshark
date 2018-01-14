# blob2wireshark

Is a plugin for wireshark, which helps to analyse binaries arrays or blob by dissectors

plugin functions:

* convert bin files into pcap file
* provides lua dissectors templates
* creates lua dissectors snippets depends of pseudo-c-struct-definition

## How to

### Install

1. Copy [b2ws-plugin folder](b2ws-plugin) to a [wireshark plugin folder](https://www.wireshark.org/docs/wsug_html_chunked/ChPluginFolders.html)

### Convert binary file to pcap files

Create example a binary file with:

```sh
mkdir example_build
cd example_build
cmake ../example
make
./b2ws_example_blob_writer
ls *.bin
```
1. Open Wireshark
2. Open ImportBlob windows by click on "Tools-> bw2s -> ImportBlob"
3. Click on "Change Settings", enter the path of the binary file.
    * you could also change  the fake src, dst and type field.
4. Click on "ImportBlob". Now the create a pcap file (in the same folder as the binary file) and open this file


### Create lua dissector file

1. Open Wireshark
2. Open ImportBlob windows by click on "Tools-> bw2s -> ImportBlob"
3. Click on "Create Dissector"
4. Enter a name for the dissector and press ok. Now the plugin create a "default" lua dissector file in the b2ws-plugin folder.  This file can und should be edit by you, e.g. add/change ProtoField or add protocol layes (see [wiki.wireshark LuaAPI/](https://wiki.wireshark.org/LuaAPI/)).
