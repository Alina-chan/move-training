// Check the documentation for more information on Sui SDK module packages:
// https://sui-typescript-docs.vercel.app/typescript#module-packages
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';

// Import our helper functions.
import { getKeypairEd25519 } from './helpers';

// Load environment variables from .env file.
import * as dotenv from 'dotenv';
dotenv.config();

// Create a SuiClient instance for testnet.
// You can also use mainnet, devnet, or localnet.
const client = new SuiClient({
  url: getFullnodeUrl('testnet')
});

// Read the private key from the environment variable.
const adminPrivateKey = process.env.ADMIN_PRIVATE_KEY!;

// Also read the package ID from the environment variable.
const packageId = process.env.PACKAGE_ID!;

// Make a keypair out of the private key.
// We will use this key pair to sign the transaction as the admin.
const adminKeypair = getKeypairEd25519(adminPrivateKey);

// Get the admin public address from the keypair.
const adminAddress = adminKeypair.getPublicKey().toSuiAddress()


// Testing the mint function. 
const mintPlayer = async () => {
  const tx = new TransactionBlock();

  const playerObject = tx.moveCall({
    target: `${packageId}::tft::mint_player`,
    arguments: [
      tx.pure("alina", "string"), // username
      tx.pure("https://placehold.co/600x400/FFF000/000?text=yo", "string"), // image url
    ],
  });
  
  tx.transferObjects([playerObject], tx.pure(adminAddress, 'address'));
  tx.setGasBudget(100000000);

  // Sign the transaction with the admin keypair.
  const response = client.signAndExecuteTransactionBlock({
    signer: adminKeypair,
    transactionBlock: tx,
    requestType: 'WaitForLocalExecution',
    options: {
      showEffects: true,
      showEvents: true,
      showObjectChanges: true,
    },
  });

  return response;
}

const main = async () => {
  // Call the mint function.
  const response = await mintPlayer();
  console.log("-------- Mint response: --------");
  console.log(response);
}


main().catch(console.error);
