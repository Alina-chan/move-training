#[test_only]
module teamfight_tactics::tft_test {
  // import anything related to the tests we want to run
  use sui::test_scenario::{Self as ts};
  use sui::transfer;
  use teamfight_tactics::tft::{Self as tft, Player};
  use sui::object;
  use std::string::{utf8};
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
    debug::print(&admin_cap);
    
    // Mint a new champion object
    ts::next_tx(&mut test_scenario, ADMIN);
    let champ = tft::mint_champion(
      &admin_cap,
      utf8(b"Soraka"),
      utf8(b"image.com"),
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
}