# README

25/10 crowdsourcing app.

How it works:

## Scenario: Starting a challenge

- When challenge administrator visits www.twentyfiveten.com
- And creates a challenge
- Then they receive a public challenge URL and a private challenge admin URL

### 01 - Homepage

![01 - Homepage](docs/01 - Homepage.png)

### 02 - New challenge

![02 - New challenge](docs/02 - New challenge.png)

### 03 - list challenges

![03 - list challenges](docs/03 - list challenges.png)

## Scenario: Participating in a challenge

- When a challenge participant visits the public challenge URL
- Then they are shown a holding screen and given a chance to enter their proposed solution

### 04 - participate

![04 - participate](docs/04 - participate.png)

### 05 - Submit idea

![05 - Submit idea](docs/05 - Submit idea.png)

![05b - Submit idea](docs/05b - Submit idea.png)

![05c - Submit idea](docs/05c - Submit idea.png)

### 06 - idea submitted

![06 - idea submitted](docs/06 - idea submitted.png)

## Scenario: Monitoring proposals

- When a challenge administrator has shared a challenge URL with participants
- And participants have started submitting their proposals
- Then the challenge admininistrator can see how many participants have registered and of those, how many have submitted their proposals

### 07 - admin waiting for participants

![07 - admin waiting for participants](docs/07 - admin waiting for participants.png)


## Scenario: Initiation of voting

- When the challenge administrator is satisfied that all submissions have been received
- And they initiate voting
- Then all participants can start voting on the first round of voting
- And the challenge administrator can see how many votes have been cast for round 1

### 07b - administrator opens voting

![07b - administrator opens voting](docs/07b - administrator opens voting.png)

### 08 - participant casts vote

![08 - participant casts vote](docs/08 - participant casts vote.png)

![08b - participant casts vote](docs/08b - participant casts vote.png)

## Scenario: Initiation of subsequent rounds of voting

- When the challenge administrator is satisfied that all votes have been cast for a round
- Then they can initiate the next round of voting
- Then all participants can start voting on the next round of voting
- And the challenge administrator can see how many votes have been cast for that round

### 09 - admin opens next voting round

![09 - admin opens next voting round](docs/09 - admin opens next voting round.png)

## Scenario: Conclusion of voting

- When a challenge administrator is satisfied that all votes have been cast
- Then they can conclude voting and close the challenge
- And all participants and the challenge administrator can see the challenge and proposed solutions, ordered in descending order of score


### 10 - admin concludes voting

![10 - admin concludes voting](docs/10 - admin concludes voting.png)

![10b - admin concludes voting](docs/10b - admin concludes voting.png)

### 11 - summary of results

![11 - summary of results](docs/11 - summary of results.png)

