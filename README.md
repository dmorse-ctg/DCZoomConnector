
# DCZoomConnector

# Introduction

 DCZoom Connector is an integrated app that aims at providing an easy-to-use interface that can be placed on any Salesforce object record to fascilitate in setting up Zoom meetings and webinars. 

The app is Lightning compatible and has a similar UI for both the Salesforce Classic as well as Lightning experience.

# Known Issues

1. When Deleting a meeting, Zoom does not send out an email to notify invitees that the meeting is Cancelled.

# Workarounds
1. Deleting a meeting - You can delete a meeting from the zoom server.Once done on the server then all invitees will be notified


# Unsupported
1. If the meeting is deleted from the zoom server then all invitees will get a cancelled email, but this is not propagated back to salesforce, therefore the salesforce zoom record is 
   not updated to reflect a cancellation

# Salesforce Installation Package

Below is the salesforce installation package url

Installation url : [dcZoomConnector v1.7 ](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2x000003alXd&isdtp=p1).
