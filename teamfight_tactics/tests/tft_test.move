#[test_only]
module teamfight_tactics::tft_test {
  // import anything related to the tests we want to run
  use sui::test_scenario::{Self as ts};
  use sui::transfer;
  // use sui::table;
  use teamfight_tactics::tft::{Self as tft, Player};
  use sui::object;
  use std::string::{utf8, String};
  use std::debug;

  // Test addresses.
  const ADMIN: address = @0x01;
  const USER: address = @0x02;

  #[test]
  fun test_mint_player() {
    // Begin a new test scenario.
    let test_scenario = ts::begin(USER);

    // Mint a new player object
    let playerObj = tft::mint_player(
      utf8(b"Alex"),
      utf8(b"image.com"),
      ts::ctx(&mut test_scenario)
    );

    // Keep track of the object id we minted.
    let objId = tft::get_player_id(&playerObj);
    let id1 = *object::uid_as_inner(objId);
    // debug::print(&id1);

    // Transfer the object to the user.
    ts::next_tx(&mut test_scenario, USER);
    transfer::public_transfer(playerObj, USER);

    // Get the object back from the user.
    ts::next_tx(&mut test_scenario, USER);
    let temp_obj = ts::take_from_sender<Player>(&test_scenario);
    let temp_obj_id = tft::get_player_id(&temp_obj);
    let id2 = *object::uid_as_inner(temp_obj_id);

    // debug::print(temp_obj_id);
    
    // Check whether the object we got back is the same as the one we minted.
    assert!(id1 == id2, 1);

    ts::return_to_sender(&test_scenario, temp_obj);

    // End the test scenario.
    ts::end(test_scenario);
  }

  #[test]
  fun test_mint_champion() {
    // Begin a new test scenario.
    let test_scenario = ts::begin(ADMIN);

    // Run the init function in test mode, which mints
    // an AdminCap and sends it to the admin.
    tft::test_init(ts::ctx(&mut test_scenario));

    ts::next_tx(&mut test_scenario, ADMIN);

    // Check if admin has the AdminCap.
    let admin_cap = ts::take_from_sender<tft::AdminCap>(&test_scenario);
    // debug::print(&admin_cap);
    
    // Mint a new champion object
    ts::next_tx(&mut test_scenario, ADMIN);
    let champ = tft::admin_mint_champion(
      &admin_cap,
      utf8(b"Soraka"),
      1,
      8,
      1, 
      14,
      vector<String>[utf8(b"Divine"), utf8(b"Mystic")],
      );

    // Transfer champion to user
    ts::next_tx(&mut test_scenario, ADMIN);

    // Since champion doesn't have store, we can't transfer it to user
    // so, we'll burn it. 
    tft::test_burn_champion(champ);

    // Return admin cap to admin
    ts::return_to_sender(&test_scenario, admin_cap);

    // End the test scenario.
    ts::end(test_scenario);
  }

  #[test]
  fun test_champion_pool_object() {
    let test_scenario = ts::begin(ADMIN);

    // Run the init function in test mode, which mints
    // ChampionPool and makes it a shared object.
    tft::test_init(ts::ctx(&mut test_scenario));

    // Check if ChampionPool shared object exists. 
    ts::next_tx(&mut test_scenario, ADMIN);
    let champion_pool = ts::take_shared<tft::ChampionPool>(&test_scenario);
    debug::print(&champion_pool);

    // Return the ChampionPool shared object.
    ts::next_tx(&mut test_scenario, ADMIN);
    ts::return_shared<tft::ChampionPool>(champion_pool);

    // End the test scenario.
    ts::end(test_scenario);
  }

  // --- TODO: Implement a test function that ---
  // - runs the test init, to issue an admincap to the admin
  // - mints a player object and transfers to the user
  // - mints a new champion object
  // - adds the champion to the player's team
  // - return all necessary objects to their owners

  #[test]
  fun test_add_champion_to_team() { 
    // Create test scenario.
    let test_scenario = ts::begin(ADMIN);

    // Run the test_init to issue an admincap to the admin.
    tft::test_init(ts::ctx(&mut test_scenario));

    // Create a player object and transfer it to the user's player.
    ts::next_tx(&mut test_scenario, ADMIN);
    let player = tft::mint_player(
      utf8(b"Zilean"), 
      utf8(b"image.com"),
      ts::ctx(&mut test_scenario)
    );
    
    // Give some gold to the player
    tft::update_player_gold(100, &mut player);

    // Transfer the player object to the user.
    ts::next_tx(&mut test_scenario, ADMIN);
    transfer::public_transfer(player, USER);

    // Mint a new champion object
    let admin_cap = ts::take_from_sender<tft::AdminCap>(&test_scenario);  // Warning! Anything you take, you must send back to user (consume)
    ts::next_tx(&mut test_scenario, ADMIN);
    let champion = tft::admin_mint_champion(
      &admin_cap,
      utf8(b"Soraka"), 1, 8, 1, 14,
      vector<String>[utf8(b"Divine"), utf8(b"Mystic")],
      ); // Who's the owner of this champion?

    // TODO Add Soraka to the champion pool - WARNING: Champion pool is a shared object!
    ts::next_tx(&mut test_scenario, USER);
    let champion_pool = ts::take_shared<tft::ChampionPool>(&test_scenario);
    let champion_name = *tft::get_champion_name(&champion);
    tft::add_champion_to_pool(champion, &mut champion_pool);

    // Get the player object back from the user.
    let player = ts::take_from_sender<tft::Player>(&test_scenario);

    // Add it to the player's team
    tft::add_champion_to_team(
      &mut player, 
      &mut champion_pool,
      champion_name,
    );

    // Return player object to user
    ts::return_to_sender(&test_scenario, player);

    // Return admin related objects to admin
    ts::next_tx(&mut test_scenario, ADMIN);
    ts::return_to_sender(&test_scenario, admin_cap);

    // Return shared object 
    ts::return_shared(champion_pool);

    // End test
    ts::end(test_scenario);
  }

}