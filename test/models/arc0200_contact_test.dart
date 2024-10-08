import 'package:flutter_test/flutter_test.dart';
import 'package:kibisis/models/arc0200_contract.dart';

void main() {
  const algodURL = 'https://testnet-api.voi.nodly.io';

  group('decimals', () {
    test('should get the decimals', () async {
      // arrange
      final contract = ARC0200Contract(
        appID: BigInt.from(6779767),
        algodURL: algodURL,
      );
      // act
      final result = await contract.decimals();

      // assert
      expect(result, 6);
    });
  }, skip: true);

  group('name', () {
    test('should get the name', () async {
      // arrange
      final contract = ARC0200Contract(
        appID: BigInt.from(6779767),
        algodURL: algodURL,
      );
      // act
      final result = await contract.name();

      // assert
      expect(result, 'Voi Incentive Asset');
    });
  }, skip: true);

  group('symbol', () {
    test('should get the symbol', () async {
      // arrange
      final contract = ARC0200Contract(
        appID: BigInt.from(6779767),
        algodURL: algodURL,
      );
      // act
      final result = await contract.symbol();

      // assert
      expect(result, 'VIA');
    });
  }, skip: true);

  group('totalSupply', () {
    test('should get the total supply', () async {
      // arrange
      final contract = ARC0200Contract(
        appID: BigInt.from(6779767),
        algodURL: algodURL,
      );
      // act
      final result = await contract.totalSupply();

      // assert
      expect(result, BigInt.parse('10000000000000000'));
    });
  }, skip: true);
}
