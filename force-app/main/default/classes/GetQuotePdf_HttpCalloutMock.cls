@isTest
global with sharing class GetQuotePdf_HttpCalloutMock implements HttpCalloutMock{

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {

        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/pdf');
        response.setBody('This is a test string');
        response.setStatusCode(200);
        return response; 
    }
}