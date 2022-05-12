## TSG Global | Take Home Project


### Telecom Rating Engine

Thanks again for applying for a job at TSG Global!

We’d like to better assess your technical skills and have developed a messaging and voice call detail record (CDR) “rating engine” project to better understand how you think. This test should generally take few hours to complete. If you need clarification about an ask on the test, just send us an email at developers@tsgglobal.com and we will get back to you shortly. Please read this entire document first, including the overall evaluation criteria, before starting on your solution.


## Overview


#### Definitions

**Call Detail Record (CDR)**

a row of data that contains to/from number, client ID and name, direction of the message/call, service type, success, number of units used, and carrier used. For this task all our CDRs are SMS, but you should assume that we offer more than one service. Term CDRs is legacy from times when telecom was only about voice calls, but it is nothing else but a transaction log for provided service (any service).

#### Use case


Customers CLT1, CLT3, and CLT2 are all TSG Global customers who consume our services.

TSG Global uses our vendors - telecom carriers named A, B, and C - to receive and deliver these services (SMS, MMS, voice calls, some APIs with data services etc). In this task we will deal with SMS service CDRs, but as you can see there could be many different services and one customer can use few different services from us. 

TSG Global bills our customers based on CDRs, meaning that they are billed based on the amount of units used. Sell rates are customer specific and are provided in sell_rates.csv.


We are providing you two sample CSVs:

*   Some sell rates that we charge our customers (per-unit).
*   Some 200 call detail records (CDRs) include the information necessary to appropriate “rate” the CDRs based on the previous two files. When designing solution please keep in mind that average customer daily makes few million transactions and this 200 CDRs is just a small subset of those.

Data provided in the files is provisional - feel free to structure your data models as you find that it fits best for this solution.

Your take home project consists of two steps:

## Step 1) Create a CDR importer for rating

#### Task

 Your first step is to create a backend system which should read the supplied 200 line CDR file, as well as accept new CDRs via a POST, and accurately decode, rate, and store to a data storage the appropriate amounts a customer should be charged.

##### POST - New Call Detail Record (CDR)

With this public API, we should be able to add a new CDR and data should be stored in the data storage and rated properly. Relevant data fields should be provided in the request body with an exception of CDR timestamp which should be optional and should default to UTC now in case not explicitly provided.

**Note: part of the evaluation will include us POSTing new CDRs to your API (after first evaluating how you rated/billed the existing 200 line CDR CSV).**

The provided CSV files to help with this task are:

#### Sell Rates - sell_rates.csv

This file contains example current TSG Global pricing for voice/messaging transport that we offer to businesses. Individual clients have different service fees for different services. If any data is missing, that means we don’t provide such service for this client at the moment.

Columns mappings are following:



1. Client code
2. Price start date
3. SMS fee (per unit)
4. MMS fee (per unit)
5. Voice fee (per unit)
6. Direction


#### Call Detail Records (CDRs) - cdrs.csv

This file contains example rows of data about a service we provided to the client (client succeeded to send/receive a message or call/received a call).

Columns mappings are as follows:



1. Client code
2. Client name
3. Source number (number that initiated the service)
4. Destination number
5. Direction:
*   Inbound - if client received message/call
*   Outbound - if client sent message or made a call
6. Service type (SMS, MMS or Voice)
7. Success (true or false)
8. Carrier
9. Timestamp_UTC


## Step 2) Create a GET billing JSON API


#### Task

Now that you have some code/an API that can correctly ingest the CDR data data provided to you, we’d like a way to query (GET) a client and see what their monthly bill currently is. Please create another JSON API with a public endpoint that we can query.


#### GET - Client Monthly Service Charges

For a provided **client code, month, and year,** your API should return the information about the **total services provided, total cost per service, and grand total across all services.**


##### Example


<table>
  <tr>
   <td>Service
   </td>
   <td>Count (successful units)
   </td>
   <td>Total price
   </td>
  </tr>
  <tr>
   <td>SMS
   </td>
   <td>22
   </td>
   <td>2.50
   </td>
  </tr>
  <tr>
   <td>MMS
   </td>
   <td>4
   </td>
   <td>0.40
   </td>
  </tr>
  <tr>
   <td>TOTAL
   </td>
   <td>26
   </td>
   <td>2.90
   </td>
  </tr>
</table>

## Bonus - simple frontend

Frontend work is not part of this assignment and we will test the API using curl, Postman or so, but we will not complain if you build a very simple (doesn't have to be pretty) like one or two pages front for these two API endpoints. 

## Overall Evaluation criteria

Your solution can be submitted in any language of your preference but bonus points will be scored for submitting an Elixir solution since you are applying for Elixir position.

We are looking for **clean, readable, performant and maintainable code.**

Please use THIS GitHub repository to upload your code (feel free to reorganize/delete current files as you like). Feel free to commit as you work - we will only review it once you let us know it's done.

Please include a readme with the prerequisites and detailed instructions on how to run the solution. 

Since this is not expected to be a production ready code you are allowed to take shortcuts to reduce your development time, but if any assumptions or trade-offs have been made, those should be documented (comment in code or in your project readme is fine). Eg. some services in CDRs csv have success status set to false, if you notice that but you decide to rate those anyway leave a comment so we are aware of that during review. :)

In general, if you have any doubts and find your self on the crossroads feel free to take any path you think fits better - this is pretty open ended task so whatever you decide is fine as long as you leave a note for reviewers to know your decision.

Once you are complete, simply let us know - and we will be in touch within a day or two. Next step would be technical interview.


## Technical interview

Technical interview takes up to 1 hour. First we spend some time discussing your solution and afterwards we ask a few general technical questions. It is not mandatory to try to give answers to all the questions - if there is something you are not familiar with you can let us know and we will move to another question and that is totally fine.

At the end of the interview we always leave time if you have any questions for us, but in general if you come up with a question during the interview please don't hesitate to ask - idea is that this interview should be as relaxed as possible.

If you have any questions related to the position, this task, our work culture or TSG in general please don't hesitate to email us at developers@tsgglobal.com at any time. 