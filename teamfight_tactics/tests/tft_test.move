#[test_only]
module teamfight_tactics::tft_test {
  // import anything related to the tests we want to run
  use sui::test_scenario::{Self as ts};
  use sui::transfer;
  use sui::table;
  use teamfight_tactics::tft::{Self as tft, Player};
  use sui::object;
  use std::string::{utf8, String};
  use std::debug;

  const ADMIN: address = @0x01;
  const USER: address = @0x02;

  #[test]
  fun test_mint_player() {
    // Begin a new test scenario.
    let test_scenario = ts::begin(USER);

    // Mint a new player object
    let playerObj = tft::mint_player(
      utf8(b"Alex"),
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
    debug::print(&admin_cap);
    
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

  // --- TODO: Implement a test function that ---
  // - runs the test init, to issue an admincap to the admin
  // - mints a player object and transfers to the user
  // - mints a new champion object
  // - adds the champion to the player's team
  // - return all necessary objects to their owners

  #[test]
  fun test_add_champion_to_team() { 
    // Create test scenario for the Admin
    let admin_test_scenario = ts::begin(ADMIN);
    let user_test_scenario = ts::begin(USER);

    // Run the test_init to issue an admincap to the admin
    tft::test_init(ts::ctx(&mut admin_test_scenario));

    // Create a player object and transfer it to the user's player
    let player = tft::mint_player(utf8(b"Zilean"), 
      ts::ctx(&mut user_test_scenario));
    
    ts::next_tx(&mut user_test_scenario, USER);
    transfer::public_transfer(player, USER);

    // Mint a new champion object
    let admin_cap = ts::take_from_sender<tft::AdminCap>(&admin_test_scenario);  // Warning! Anything you take, you must send back to user (consume)
    ts::next_tx(&mut admin_test_scenario, ADMIN);
    let champion = tft::admin_mint_champion(
      &admin_cap,
      utf8(b"Soraka"), 1, 8, 1, 14,
      vector<String>[utf8(b"Divine"), utf8(b"Mystic")],
      ); // Who's the owner of this champion?

    // TODO Add Soraka to the champion pool - WARNING: Champion pool is a shared object!
    let champion_pool = ts::take_shared<tft::ChampionPool>(&admin_test_scenario);
    table::add(&mut champion_pool.champions, utf8(b"Soraka"), champion);

    // Add it to the player's team
    tft::add_champion_to_team(
      &mut player, 
      &mut champion_pool,
      utf8(b"Soraka")
      );

    // TODO: Consume (e.g. delete/burn) the champion pool object
    
    ts::end(user_test_scenario);
    ts::return_to_sender(&admin_test_scenario, admin_cap);
    ts::end(admin_test_scenario);
  }

}