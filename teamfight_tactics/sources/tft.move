module teamfight_tactics::tft {
  // Sui imports. 
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::package; 
  use sui::display;
  use sui::event; 
  use sui::dynamic_field as df;

  // STD imports. 
  use std::string::{utf8, String};
  use std::vector;
  use std::option::{Self, Option};

  struct Player has key, store {
    id: UID,
    username: String,
    addr: address,
    health: u64, 
    gold: u64, 
    team: vector<Champion>,
    // image_url: String,
    image_url: Option<String>,
  }

  // Event object for when we mint a new player. 
  struct MintPlayerEvent has copy, drop {
    player_id: ID,
  }

  // Create an Admin capability to allow admins to mint champions.
  // We skip adding store so that even the Admin cannot transfer the capability to someone else.
  struct AdminCap has key {
    id: UID,
  }

  struct ChampionPool has key, store{
    id: UID,
    champions: vector<Champion>,
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

  ///
  /// Champion {
  ///   name: Soraka
  ///   cost: 2
  ///   tier: 2
  ///   copies: 14
  ///   traits: vector["sorcerer", "healer"]
  /// }
  /// 
  /// Champion {
  ///   name: Soraka
  ///   cost: 2
  ///   tier: 2
  ///   copies: 1
  ///   traits: vector["sorcerer", "healer"]
  /// }
  /// 
  /// 
  /// 
  /// 
  /// 
  // Create a one-time-witness for publisher.
  struct TFT has drop {}

  // Initialize the TFT module.
  // This function is called once when the module is published.
  fun init(otw: TFT, ctx: &mut TxContext) {
    // Create publisher object from OTW. 
    let publisher = package::claim(otw, ctx);

    let admin_cap = AdminCap {
      id: object::new(ctx),
    };

    let pool = ChampionPool {
      id: object::new(ctx),
      champions: vector::empty(),
    };
    
    // Set up the display for champions. 
    let keys = vector[
      utf8(b"username"),
      utf8(b"image_url"),
    ];

    let values = vector[
      utf8(b"{username}"),
      utf8(b"ipfs://{image_url}"), // ipfs://asdjahgdsjhdfgsf.png
    ];

    let display = display::new_with_fields<Player>(
      &publisher, keys, values, ctx
    );
    
    display::update_version(&mut display);
    
    // We can transfer only if store is added to the AdminCap.
    // transfer::public_transfer(admin_cap, tx_context::sender(ctx));

    // Custom transfer allows us to transfer the capability even if store is not added.
    custom_transfer_for_admincap(admin_cap, ctx);

    // Transfer the publisher object to the sender/signer.
    transfer::public_transfer(publisher, tx_context::sender(ctx));

    // Send the display object to sender/signer.
    transfer::public_transfer(display, tx_context::sender(ctx));

    // Publicly share pool object because we want players to access it.
    transfer::share_object(pool);
  }


  /// Mints and returns a Player object. 
  public fun mint_player(
    username: String, image_url: String, ctx: &mut TxContext
  ): Player {
    // Create a new player object.
    let player = Player {
      id: object::new(ctx),
      username,
      addr: tx_context::sender(ctx),
      health: 100,
      gold: 0,
      team: vector::empty(),
      image_url: option::some<String>(image_url),
    };

    // Construct the event object.
    let event = MintPlayerEvent {
      player_id: *object::uid_as_inner(&player.id),
    };

    // Emit the event.
    event::emit(event);

    // Return the player object.
    player
  }


  /// Mints and transfers a Player object.
  public fun mint_and_transfer_player(
    username: String, image_url: String, ctx: &mut TxContext
  ) {
    // Call mint_player which returns a player object.
    let player = mint_player(username, image_url, ctx);

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
      image_url: _
    } = player;

    // Delete the team vector by hand because Champion doesn't have the drop ability.
    vector::destroy_empty(team); // We assume the vector is empty.

    // Delete the player object.
    object::delete(id);
  }


  // --- TODO: Implement the function `burn_player_advanced` ---
  
  /// Burn a player object that also has a non empty team vector.
  public fun burn_player_advanced(player: Player) {
    // - You need to pass the Player object to the function.
    // - You need to check if the team vector is empty or not.
    // - If vector is not empty, remove all Champion objects from the vector.
    // - Delete (with destructure) the player object.
    // - Destroy the team vector.
    // - Delete the player object.
    
    // Hint: Check the std::vector and sui::object modules to find functions that 
    // can help you.

     let Player {
      id,
      username: _,
      addr: _,
      health: _,
      gold: _,
      team,
      image_url: _
    } = player;

    if (vector::is_empty(&team)) {
      vector::destroy_empty(team);
    } else {
      let len = vector::length(&team);
      let i = 0;

      while (i < len) {
        let champion = vector::pop_back(&mut team);

        let Champion {
          name: _,
        } = champion; 


        i = i + 1;
      };

      vector::destroy_empty(team);
    };

    object::delete(id);

  }

  // Update player health.
  public fun update_health(new_health: u64, player: &mut Player) {
    player.health = new_health;
  }

  // Only the admin can mint champions.
  public fun mint_champion(
    _cap: &AdminCap, name: String, _image_url: String
  ): Champion {
    let champion = Champion {
      name,
    };
    
    // Return the champion object.
    champion
  }

  // --- TODO (optional): Implement a function `add_champion_to_team` ---
  // - The function should add a champion to the player's team vector.


  // --- Helper functions ---

  // Private function to transfer the AdminCap capability.
  public fun custom_transfer_for_admincap(cap: AdminCap, ctx: &mut TxContext) {
    transfer::transfer(cap, tx_context::sender(ctx));
  }

  // fun test(champion: Option<Champion>) {
  //   if (option::is_some(&champion)) {
  //     // do something if a champion is present
  //   } else {
  //     // do something else, without the program failing
  //   };
  // }

  public fun add_rank_to_player(player: &mut Player, rank: u64) {
    df::add<String, u64>(&mut player.id, utf8(b"rank"), rank);
  }

  public fun update_rank_for_player(player: &mut Player, rank: u64) {
    if(df::exists_(&player.id, rank)) {
      let player_rank = df::borrow_mut<String, u64>(&mut player.id, utf8(b"rank"));
      *player_rank = rank;
    } else {
      add_rank_to_player(player, rank);
    }
  }
}