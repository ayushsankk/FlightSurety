const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');
const Web3 = require('web3');

module.exports = async(deployer, network, accounts) => {
  let firstAirline = accounts[1];

  await deployer.deploy(FlightSuretyData);

  // Add and register the first airline during deploy
  let dataContract = await FlightSuretyData.deployed();
  await dataContract.addAirline(firstAirline, "Etihad Airlines");
  await dataContract.addToRegisteredAirlines(firstAirline);

  // Deploy the app logic contract and authorize it with the data contract
  let appContract = await deployer.deploy(
    FlightSuretyApp, FlightSuretyData.address);
  await dataContract.authorizeCaller(FlightSuretyApp.address);

  // Fund the contract using the first airline
  await appContract.submitAirlineRegistrationFund(
    {from: firstAirline, value: Web3.utils.toWei('10', "ether")});

  // Add some dummy data for demo purposes
  const timestamp = Math.floor(Date.now() / 1000);
  await appContract.registerFlight(firstAirline, '432-123', timestamp);
  await appContract.registerFlight(firstAirline, '243-352', timestamp);
  await appContract.registerFlight(firstAirline, '122-432', timestamp);

  let config = {
    localhost: {
        url: 'http://localhost:8545',
        dataAddress: FlightSuretyData.address,
        appAddress: FlightSuretyApp.address
    }
  }
  fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
  fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
};
