import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { Secp256k1Keypair } from '@mysten/sui.js/keypairs/secp256k1';
import { fromB64 } from '@mysten/bcs';

/// --- Helper functions to make keypairs from private keys ---

export function getKeypairEd25519(privateKey: string): Ed25519Keypair {
  let privateKeyArray = Array.from(fromB64(privateKey));
  privateKeyArray.shift();
  return Ed25519Keypair.fromSecretKey(Uint8Array.from(privateKeyArray));
}

export function getKeypairSecp256k1(privateKey: string): Secp256k1Keypair {
  let privateKeyArray = Array.from(fromB64(privateKey));
  privateKeyArray.shift();
  return Secp256k1Keypair.fromSecretKey(Uint8Array.from(privateKeyArray));
}