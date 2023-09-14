module teamfight_tactics::tft {
  // Sui imports. 
  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::{Self};
  use sui::table;

  // STD imports. 
  use std::string::{String};

  const ENotEnoughGold: u64 = 1;
  const EChampionNotInPool: u64 = 2;
  const EChampionNotAvailable: u64 = 3;

  struct Player has key {
    id: UID,
    username: String, 
    addr: address,
    health: u64, 
    gold: u64, 
    team: table::Table<String, Champion>,
  }

  struct AdminCap has key { id: UID }

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

  // Initialize the TFT module.
  // This function is called once when the module is published.
  fun init(ctx: &mut TxContext) {
    // Create the admin cap object.
    let admin_cap = AdminCap { id: object::new(ctx) };
    // Transfer the admin cap object to the sender/signer.
    transfer::transfer(admin_cap, tx_context::sender(ctx));

    // Share the champion pool object so that it can be accessible by every player.
    transfer::share_object(ChampionPool {
      id: object::new(ctx),
      champions: table::new<String, Champion>(ctx), // empty table
    });
  }

  /// Mints and returns a Player object. 
  public fun mint_player(
    _admin_cap: &AdminCap, 
    username: String, 
    ctx: &mut TxContext): Player {
    
    // Create a new player object.
    let player = Player {
      id: object::new(ctx),
      username,
      addr: tx_context::sender(ctx),
      health: 100,
      gold: 0,
      team: table::new<String, Champion>(ctx), // empty table
    };

    // Return the player object.
    player
  }

  /// Mints and transfers a Player object.
  public fun mint_and_transfer_player(
    admin_cap: &AdminCap, 
    username: String, 
    ctx: &mut TxContext
  ) {
    // Call mint_player which returns a player object.
    let player = mint_player(admin_cap, username, ctx);

    // Transfer the player object to the sender/signer.
    transfer::transfer(player, tx_context::sender(ctx));
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
    table::destroy_empty(team); // We assume the vector is empty.

    // Delete the player object.
    object::delete(id);
  }


  /// Burn a player object that also has a non empty team vector.
  public fun burn_player_advanced(player: Player) {
    let Player {
      id,
      username: _,
      addr: _,
      health: _,
      gold: _,
      team,
    } = player;
    if (table::is_empty(&team)) {
      table::destroy_empty(team);
    } else {
      table::drop(team);
    };
    object::delete(id);

    // Hint: Check the std::vector and sui::object modules to find functions that 
    // can help you.
  }

  // Update player health.
  public fun update_health(new_health: u64, player: &mut Player) {
    player.health = new_health;
  }

  /// Mint a champion for the champion pool
  fun admin_mint_champion(
    _admin_cap: &AdminCap,
    name: String,
    level: u8,
    cost: u64,
    tier: u8,
    copies: u64,
    traits: vector<String>): Champion {

    Champion {
      name,
      level,
      cost,
      tier,
      copies,
      traits
    }
  }

  // - The function should add a champion to the player's team vector.
  // Essentially the player "buys" a champion from the champion pool and
  // puts it on her team.
  public fun add_champion_to_team(
    player: &mut Player,
    champion_pool: &mut ChampionPool,
    champion_name: String) {
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
}