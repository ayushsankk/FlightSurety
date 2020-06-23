import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.firstAirline = null;
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];
            this.firstAirline = accts[1];

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.firstAirline,
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    buyInsurance(flight, insuranceValue, callback) {
        let self = this;
        let payload = {
            airline: self.firstAirline,
            flight: flight,
        }
        self.flightSuretyApp.methods
            .buyInsurance(payload.airline, payload.flight)
            .send({from: self.owner, value: this.web3.utils.toWei(insuranceValue, "ether"), gas: 9999999}, (error, result) => {
                callback(error, result);
            });
    }

    withdrawCredits(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .withdrawCredits()
            .send({ from: self.owner, gas: 9999999}, (error, result) => {
                callback(error, result);
            });
    }
}
