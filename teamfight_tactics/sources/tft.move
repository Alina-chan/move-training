module teamfight_tactics::tft {
  // Sui imports. 
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::table;
  use sui::package; 
  use sui::display;
  use sui::event; 
  use sui::dynamic_field as df;

  // STD imports. 
  use std::string::{utf8, String};
  // use std::vector;
  use std::option::{Self, Option};

  // Error codes.
  const ENotEnoughGold: u64 = 1;
  const EChampionNotInPool: u64 = 2;
  const EChampionNotAvailable: u64 = 3;

  struct Player has key, store {
    id: UID,
    username: String, 
    addr: address,
    health: u64, 
    gold: u64, 
    team: table::Table<String, Champion>,
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

  // --- TODO: Enrich the Champion struct ---
  // - Add extra fields to the Champion struct: 
  // -- cost (how much gold the champion costs)
  // -- tier (what tier the champion is, can be 1 <= tier <= 5)
  // -- copies (how many copies of the champion the player owns)
  // -- traits (what traits the champion has, e.g. "bruiser", "sorcerer", etc.)
  // Hint: You can use the `vector` module to store the traits, or find a better
  // solution from the Sui library. -- Ans: I prefered doing this for the Player.team
  struct Champion has store, drop, copy {
    name: String,
    level: u8,
    cost: u64,
    tier: u8,
    copies: u64,
    traits: vector<String>, 
  }

  /// The admin creates a pool of champions of which players can buy from.
  struct ChampionPool has key {
    id: UID,
    champions: table::Table<String, Champion>
  }

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
      champions: table::new<String, Champion>(ctx), // empty table
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
      team: table::new<String, Champion>(ctx), // empty table
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
    _admin_cap: &AdminCap, username: String, image_url: String, ctx: &mut TxContext
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
      image_url: _,
    } = player;

    // Delete the team vector by hand because Champion doesn't have the drop ability.
    table::destroy_empty(team); // We assume the vector is empty.

    // Delete the player object.
    object::delete(id);
  }


  // --- TODO: Implement the function `burn_player_advanced` --
  /// Burn a player object that also has a non empty team vector.
  public fun burn_player_advanced(player: Player) {
    // - You need to pass the Player object to the function.
    // - You need to check if the team vector is empty or not.
    // - If vector is not empty, remove all Champion objects from the vector.
    // - Delete (with destructure) the player object.
    // - Destroy the team vector.
    // - Delete the player object.
    let Player {
      id,
      username: _,
      addr: _,
      health: _,
      gold: _,
      team,
      image_url: _,
    } = player;
    
    if (table::is_empty(&team)) {
      table::destroy_empty(team);
    } else {
      table::drop(team);
    };

    // Delete the player object.
    object::delete(id);

    // Hint: Check the std::vector and sui::object modules to find functions that 
    // can help you.

    // If team was a vector of objects, we could have used the following code:
    // if (vector::is_empty(&team)) {
    //   vector::destroy_empty(team);
    // } else {
    //   let len = vector::length(&team);
    //   let i = 0;

    //   while (i < len) {
    //     let champion = vector::pop_back(&mut team);

    //     let Champion {
    //       name: _,
    //     } = champion; 

    //     i = i + 1;
    //   };

    //   vector::destroy_empty(team);
    // };
  }

  // Update player health.
  public fun update_health(new_health: u64, player: &mut Player) {
    player.health = new_health;
  }

  // --- TODO: Implement a function `mint_champion` ---
  // - The function should mint a champion object.
  // - The function should return the champion object.
  /// Mint a champion for the champion pool
  public fun admin_mint_champion(
    _admin_cap: &AdminCap,
    name: String,
    level: u8,
    cost: u64,
    tier: u8,
    copies: u64,
    traits: vector<String>
  ): Champion {

    Champion {
      name,
      level,
      cost,
      tier,
      copies,
      traits
    }
  }

  // --- TODO (optional): Implement a function `add_champion_to_team` ---
  // - The function should add a champion to the player's team vector.
  // Essentially the player "buys" a champion from the champion pool and
  // puts it on her team.
  public fun add_champion_to_team(
    player: &mut Player,
    champion_pool: &mut ChampionPool,
    champion_name: String
  ) {
    let champion_pool_table: &mut table::Table<String, Champion> = &mut champion_pool.champions;
    
    assert!(table::contains(champion_pool_table, champion_name), EChampionNotInPool);
    let champion: &mut Champion = table::borrow_mut(champion_pool_table, champion_name);
    assert!(champion.copies > 0, EChampionNotAvailable);
    assert!(champion.cost < player.gold, ENotEnoughGold);
    player.gold = player.gold - champion.cost;

    if (table::contains(&player.team, champion_name)) {
      // Existing player champion should be updated to include one more copy of the champ.
      let player_champion: &mut Champion = table::borrow_mut(&mut player.team, champion_name);
      player_champion.copies = player_champion.copies + 1;
    } else {
      // The player doesn't have the champion yet, so we add it to the team.
      let champion: Champion = Champion {
        name: champion.name,
        level: champion.level,
        cost: champion.cost,
        tier: champion.tier,
        copies: 1,
        traits: champion.traits,
      };
      table::add(&mut player.team, champion.name, champion);
    }
  }

  // Adds a dynamic field to the player object, because it was not defined in the struct.
  public fun add_rank_to_player(player: &mut Player, rank: u64) {
    df::add<String, u64>(&mut player.id, utf8(b"rank"), rank);
  }

  // Updates the rank of the player, which is a dynamic field.
  public fun update_rank_for_player(player: &mut Player, rank: u64) {
    if(df::exists_(&player.id, rank)) {
      let player_rank = df::borrow_mut<String, u64>(&mut player.id, utf8(b"rank"));
      *player_rank = rank;
    } else {
      add_rank_to_player(player, rank);
    }
  }

  // --- Helper functions ---

  // Private function to transfer the AdminCap capability.
  public fun custom_transfer_for_admincap(cap: AdminCap, ctx: &mut TxContext) {
    transfer::transfer(cap, tx_context::sender(ctx));
  }

  // --- Accessors ---
  public fun get_player_id(player: &Player): &UID {
    &player.id
  }

  // --- Helper test functions ---
  #[test_only]
  public fun test_init(ctx: &mut TxContext) {
    init(
      TFT {},
      ctx
    );
  }

  #[test_only]
  public fun test_burn_champion(champion: Champion) {
    // Destruct the champion object.
    let Champion {
      name: _,
      level: _,
      cost: _,
      tier: _,
      copies: _,
      traits: _
    } = champion;
  }
}