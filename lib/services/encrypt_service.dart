import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class DecryptionService {
  final String privateKey;

  DecryptionService(this.privateKey);

  // Decrypt the token using RSA with private key
  String decryptToken(String encryptedToken) {
    final parser = RSAKeyParser();
    final rsaPrivateKey = parser.parse(cleanPem(privateKey)) as RSAPrivateKey;
    final encrypter = Encrypter(RSA(privateKey: rsaPrivateKey));
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(encryptedToken));
    return decrypted;
  }

  String cleanPem(String pem) {
    return pem.replaceAll(r'\n', '\n');
  }
}
