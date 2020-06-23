import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            display('', '', [ { label: 'Operational status:', error: error, value: result} ]);
        });
        
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let flightSelection = document.getElementById("flight-number");
            let flight = flightSelection.options[flightSelection.selectedIndex].value;
            let insuranceValue = DOM.elid('insurance-value').value;
            contract.buyInsurance(flight, insuranceValue, (error, result) => {
                display('Passenger', 'Buy insurance', [ { label: 'Transaction', error: error, value: result} ]);
            });
        })

        DOM.elid('withdraw-credits').addEventListener('click', () => {
            contract.withdrawCredits((error, result) => {
                display('Passenger', 'Withdraw credits', [ { label: 'Transaction', error: error, value: result} ]);
            });
        })

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ', ' + result.timestamp} ]);
            });
        })
    });
    

})();


function display(title, description, results) {
    let resultsDiv = DOM.elid("results-wrapper");
    let displayDiv = DOM.elid("display-wrapper");
    
    let section = DOM.section();
    
    section.appendChild(DOM.h5(description));
    section.appendChild(DOM.h2(title));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-10 field-value'}, result.error ? String(result.error) : String(result.value)));
        row.appendChild(DOM.div({className: 'col-sm-2 field'}, result.label));
        
        section.appendChild(row);
    })

  if (results[0].label === 'Operational status:') {
    displayDiv.append(section);
  } else {
    resultsDiv.innerHTML = '';
    resultsDiv.append(section);
  }
}
