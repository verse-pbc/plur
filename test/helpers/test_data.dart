class TestData {

  static const alicePubkey = 
      "bd91fa6ff27712408c96821435e988dee99c26db1e5e11a86a89ef5993d8782f";
  static const aliceSecretKey = 
    "02a5ba0ad772f5ade331e489f6f993c93788cef702f2c4af8d2aa2409b5c5751c5751";
  static const bobPubkey = 
    "53ba98b4f6d919e62e8a8bfe8899a3523e4c6f92f9b7d653783bcf400c6102de";
  static const bobSecretKey = 
    "51fe263b683444dfc44f0a2c2e6efe9006e4e51884141a421590c725dad6a0d9";

  static Map<String, dynamic> get groupNoteJson => {
    "kind": 11,
    "id": "4f1448b1b2f0812702a97b2fc68311d151f1e4c6e7866acb70c6ca890013a20e",
    "pubkey": "13852255dc6788860e1b5cbc77be690eb8720fdaf169f94e4196213572982aa1",
    "created_at": 1740696123,
    "tags": [
      ["h", "SW8N7TKHLDVZ"],
      ["previous"],
      ["imeta", "url https://nosto.re/27f1379eb6b27674843971155d32fc66848bbddb276936188220098f0db2c80d.jpeg", "blurhash LnC%?dROMwoJyGROV?WVIWadt7kC", "dim 1920x1279"]
    ],
    "content": "https://nosto.re/27f1379eb6b27674843971155d32fc66848bbddb276936188220098f0db2c80d.jpeg",
    "sig": "8eda26c807cbd4589932a1e077434f6423b274342b919c32aaf08ebdd1686e774542cf5f13269a80ff50688f78dfc8a56f49c1c6e2d728348a777f13cf9101de"
  };
} 