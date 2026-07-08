/*
Plan based on EDA findings:
- annualize revenue on a per asset basis based on the maximum of acquisition date and market open date
    - only if this max occurs after 2017-01-01
- drop assets that don't map to an in-scope market
- drop rentals that occurred before market open date or acquisition date
    - using the max of the two dates, since the market should be open and the asset 
    should have been acquired for the rental to truly be in-scope
    - if i don't do this and still annualize on the market/acquisition, i will overcount revenue
*/