import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class BlockchainService {
  final String _rpcUrl = 'http://192.168.0.20:7545'; // Ganache local IP
  final String _privateKey = '0x8bf7f0eb93096c07eb4fc2ba8152f5a72ff510e79d12096c376f4fd65b79aaf6'; // Replace with your private key
  late Web3Client _client;
  late EthereumAddress _contractAddress;
  late DeployedContract _contract;
  late ContractFunction _addProductFunction;
  late ContractFunction _getProductsFunction;

  BlockchainService() {
    _client = Web3Client(_rpcUrl, Client());
  }

  Future<void> init() async {
    // Replace with your contract address
    _contractAddress = EthereumAddress.fromHex('0x62fF05F5d2B5297565F27Ac058349B9B2688c0cb');

    // ABI (Application Binary Interface) for the contract
    final abi = _abi();

    // Creating the DeployedContract
    _contract = DeployedContract(
      ContractAbi.fromJson(abi.toString(), 'ProductContract'), // Name of your contract
      _contractAddress,
    );

    // Getting the contract functions
    _addProductFunction = _contract.function('addProduct');
    _getProductsFunction = _contract.function('getProducts');
  }

  List<dynamic> _abi() {
    return [
      {
        "constant": false,
        "inputs": [
          {"name": "title", "type": "string"},
          {"name": "description", "type": "string"},
          {"name": "price", "type": "uint256"},
          {"name": "quantity", "type": "uint256"},
          {"name": "image", "type": "string"}
        ],
        "name": "addProduct",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
      },
      {
        "constant": true,
        "inputs": [],
        "name": "getProducts",
        "outputs": [
          {"name": "", "type": "tuple[]", "components": [
            {"name": "title", "type": "string"},
            {"name": "description", "type": "string"},
            {"name": "price", "type": "uint256"},
            {"name": "quantity", "type": "uint256"},
            {"name": "image", "type": "string"}
          ]}
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
      }
    ];
  }

  // Add product data to blockchain
  Future<String> addProduct(
      String title,
      String description,
      BigInt price,
      int quantity,
      String image,
      ) async {
    final credentials = await _client.credentialsFromPrivateKey(_privateKey);
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _addProductFunction,
      parameters: [title, description, price, quantity, image],
    );
    final txHash = await _client.sendTransaction(credentials, transaction);
    return txHash;
  }

  // Get products from blockchain
  Future<List<Map<String, dynamic>>> getProducts() async {
    final result = await _client.call(
      contract: _contract,
      function: _getProductsFunction,
      params: [],
    );

    List<Map<String, dynamic>> products = [];
    for (var product in result[0]) {
      products.add({
        'title': product[0],
        'description': product[1],
        'price': product[2].toString(),
        'quantity': product[3].toString(),
        'image': product[4],
      });
    }

    return products;
  }

  Future<String> storeProductMetadata(String productHash) async {
    final credentials = await _client.credentialsFromPrivateKey(_privateKey);
    final sender = await credentials.extractAddress();

    // Send the product hash in a transaction
    final transaction = Transaction(
      to: EthereumAddress.fromHex(_privateKey), // Use a dummy address
      gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
      maxGas: 100000,
      data: Uint8List.fromList(utf8.encode(productHash)), // Store the product hash in transaction data
    );

    try {
      final txHash = await _client.sendTransaction(credentials, transaction, chainId: 1337); // Ganache chainId
      return txHash;
    } catch (e) {
      throw Exception('Error sending transaction: $e');
    }
  }

  // Future<String> storeProductMetadata(String productHash) async {
  //   final credentials = await _client.credentialsFromPrivateKey(_privateKey);
  //   final sender = await credentials.extractAddress();
  //
  //   final transaction = Transaction(
  //     to: sender, // Use the sender's address instead of a private key
  //     gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 20),
  //     maxGas: 100000,
  //     data: Uint8List.fromList(utf8.encode(productHash)), // Store product hash
  //   );
  //
  //   try {
  //     final txHash = await _client.sendTransaction(credentials, transaction, chainId: 1337); // Ganache chainId
  //     return txHash;
  //   } catch (e) {
  //     throw Exception('Error sending transaction: $e');
  //   }
  // }

}
