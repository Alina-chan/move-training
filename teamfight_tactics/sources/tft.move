module teamfight_tactics::tft {
  // Sui imports. 
  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};

  // STD imports. 
  use std::string::{String};
  use std::vector;

  struct Player has key, store {
    id: UID,
    username: String, 
    addr: address,
    health: u64, 
    gold: u64, 
    team: vector<Champion>,
  }

  // --- TODO: Enrich the Champion struct ---
  // - Add extra fields to the Champion struct: 
  // -- cost (how much gold the champion costs)
  // -- tier (what tier the champion is, can be 1 <= tier <= 5)
  // -- copies (how many copies of the champion the player owns)
  // -- traits (what traits the champion has, e.g. "bruiser", "sorcerer", etc.)
  // Hint: You can use the `vector` module to store the traits, or find a better
  // solution from the Sui library.
  struct Champion has store {
    name: String,
  }

  // Initialize the TFT module.
  // This function is called once when the module is published.
  // fun init() {}


  /// Mints and returns a Player object. 
  public fun mint_player(username: String, ctx: &mut TxContext): Player {
    // Create a new player object.
    let player = Player {
      id: object::new(ctx),
      username,
      addr: tx_context::sender(ctx),
      health: 100,
      gold: 0,
      team: vector::empty(),
    };

    // Return the player object.
    player
  }


  /// Mints and transfers a Player object.
  public fun mint_and_transfer_player(username: String, ctx: &mut TxContext) {
    // Call mint_player which returns a player object.
    let player = mint_player(username, ctx);

    // Transfer the player object to the sender/signer.
    transfer::public_transfer(player, tx_context::sender(ctx));
  }


  /// Burns player object.
  /// In this example we assume that the team vector is empty, thus we delete it 
  /// using `vector::destroy_empty` immediately.
  public fun burn_player_simple(player: Player) {
    // Destructure player object.
    let Player {
      id,
      username: _,
      addr: _,
      health: _,
      gold: _,
      team,
    } = player;

    // Delete the team vector by hand because Champion doesn't have the drop ability.
    vector::destroy_empty(team); // We assume the vector is empty.

    // Delete the player object.
    object::delete(id);
  }


  // --- TODO: Implement the function `burn_player_advanced` ---
  
  /// Burn a player object that also has a non empty team vector.
  public fun burn_player_advanced() {
    // - You need to pass the Player object to the function.
    // - You need to check if the team vector is empty or not.
    // - If vector is not empty, remove all Champion objects from the vector.
    // - Delete (with destructure) the player object.
    // - Destroy the team vector.
    // - Delete the player object.
    
    // Hint: Check the std::vector and sui::object modules to find functions that 
    // can help you.
  }

  // Update player health.
  public fun update_health(new_health: u64, player: &mut Player) {
    player.health = new_health;
  }

  // --- TODO: Implement a function `mint_champion` ---
  // - The function should mint a champion object.
  // - The function should return the champion object.


  // --- TODO (optional): Implement a function `add_champion_to_team` ---
  // - The function should add a champion to the player's team vector.
}