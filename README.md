# BoochatProtocol
Research Project of Creative Internet Applications Lab in Tunghai University

Boochat Protocol is designed based on Bluetooth Low Energy Technology.
And it's originally intended to use for the implementation of a mobile chat app.

The whole protocol is divided into 2 parts due to the systems, and this part is particularlly for an iOS app.
The other is for Android app, but currently not open to the public.


The protocol use the CoreBluetooth framework, and containing 6 main mechanisms:
(1) Detect Surrounding and return an array of peripheral devices
(2) Add Friend & generate ChatID
(3) Check if certain object is within detectable distance
(4) Private chat with object with certain ChatID
(5) Public chat with everyone beside
(6) Exchange surrounding information with certain object

Noted that the last mechanism is still unstable, and our team is working hard on it.
Our future goal is to form a comprehensive protocol, and though Boochat Protocol, we can build an extendable BLE MeshNetwork. 
