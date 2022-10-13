@isTest

global class CPQ_External_HttpCalloutMock implements HttpCalloutMock {
    
	// Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"impact": 0.02}');
        response.setStatusCode(200);
        return response; 
    }
}