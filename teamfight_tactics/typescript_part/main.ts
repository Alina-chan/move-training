
// import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import  { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
// import  { } from "@mysten/sui.js/transactions";
import {config} from "dotenv";

config({ path: '.env' });
export const privateKey = process.env.PRIVATE_KEY;

// TODO: Load your private key and generate a key pair that you will use to sign transactions.
let keypair = Ed25519Keypair.deriveKeypairFromSeed(privateKey as string);
