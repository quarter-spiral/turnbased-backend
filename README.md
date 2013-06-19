# Turnbased::Backend

A backend service to enable turn based multiplayer games on the Quarter Spiral platform.

## API Endpoints

The service must be accessed by HTTPS. You have to activate turn based services through ``devcenter`` to make use of any API endpoint.

### Representation of a match data response

All endpoints that return information about a match will return it in this way.

The response body will be a JSON encoded object of match data like this:

```javascript
{
  "match": {
    "uuid": MATCHUUID,
    "game": GAMEUUID,
    "players": [
      {
        "uuid": UUID1,
        "meta": {
          "faction": 1,
          "color": "#FF0000"
        }
      }
    ],
    "invitations": [
      {
        "uuid": INVITATION_UUID1,
        "player": INVITED_PLAYER_UUID
      },
      {
        "uuid": INVITATION_UUID2,
        "player": ANOTHER_INVITED_PLAYER_UUID
      },
    ],
    "meta": {
      "name": "Some match"
    },
    "started": true,
    "ended": false,
    "results": null,
    "turns": [
      {
        "player": UUID1,
        "moves": [
          {
            "player": UUID1,
            "data": {
              "unit": 123,
              "action": "move",
              "direction": "left"
            }
          }
        ]
      }
    ],
    "currentPlayer": null
  }
}
```

``turns`` is an array of moves. For the description of a move please see the *submit a move* section

``results`` is an arbitrary object that can be set by a game

### Retrieve all matches

#### Authorization

Apps or user. User can only be used when the ``player`` parameter is specified and is the UUID of the user.

#### Request

**GET** ``/matches``

##### Parameters

* **player**: UUID of a player that restricts the returned matches played by that player
* **game**: UUID of a game that restricts the returned matches to only matches of those game

##### Body

Empty.

#### Response

##### Body

Array of match data (see at top).

### Retrieve a match

#### Authorization

Apps or user. User must be a player of the match that is going to be retrieved

#### Request

**GET** ``/matches/:MATCH-UUID:``

##### Body

Empty.

#### Response

##### Body

Match data (see at top).

### Create a match

#### Authorization

Apps or user. User only if he is the only user in the ``players`` list.  This will run the ``createMatch`` script.

#### Request

**POST** ``/matches``

##### Body

JSON encoded object of match data like this:

```javascript
{
  "match": {
    "game": GAMEUUID,
    "players": [
      {
        "uuid": UUID1,
        "meta": {
          "faction": 1,
          "color": "#FF0000"
        }
      }
    ],
    "meta": {
      "name": "Some match"
    }
  }
}
```

Match must have a ``game`` set. Players must have a ``uuid`` set. Meta data for players and for matches is any arbitrary object.


#### Response

##### Body

Match data (see at top).

The returned match object comes with additional info. Especially the UUID of the match will be used for further reference.

### Add an invitation to a match

Does only work for not started games. This will run the ``addInvitation`` script.

#### Authorization

Apps or user. User must be a player of the match.

#### Request

**POST** ``/matches/:MATCH-UUID:/invitations``

##### Body

JSON encoded object of match data like this:

```javascript
{
  "invitation": {
    "player": UUID1
  }
}
```

UUID1 is the UUID of the player you want to invite to the game. Inviting an already invited player has no effect but does not result in an error, either.

#### Response

##### Body

Match data (see at top).

### Accept an invitation

Only works for not started matches. This will run the ``acceptInvitation`` script.

#### Authorization

Apps or user. User must be the player on the invitation.

#### Request

**POST** ``/matches/:MATCH-UUID:/invitations/:INVITATION-UUID:``

##### Body

Empty

#### Response

##### Body

Match data (see at top).

### Decline an invitation

Does only work for not started games. This will run the ``declineInvitation`` script.

#### Authorization

Apps or user. User must be the player on the invitation.

#### Request

**DELETE** ``/matches/:MATCH-UUID:/invitations/:INVITATION-UUID:``

##### Body

Empty

#### Response

##### Body

Match data (see at top).

### Start a match

To start a game the *next turn* endpoint must be hit.

#### Authorization

Apps or user. User must be the first player of the match.

### Next turn

Only works for matches that are started already and not ended yet. This will run the ``nextTurn`` script.

#### Authorization

Apps or user. User must be the current player of the match. If a match is not started yet user must be the first player of the match to start it.

#### Request

**POST** ``/matches/:MATCH-UUID:/turns``

##### Body

Empty

#### Response

##### Body

Match data (see at top).

### Submit a move

Only works for matches that are started already and not ended yet. This will run the ``newMove`` script.

#### Authorization

Apps or user. User must be the current player of the match.

#### Request

**POST** ``/matches/:MATCH-UUID:/moves``

##### Body

JSON encoded object of match data like this:

```javascript
{
  "move": {
    "player": UUID1,
    "data": {
      "unit": 123,
      "action": "move",
      "direction": "left"
    }
  }
}
```

The ``data`` can be an arbitrary object.

#### Response

##### Body

Match data (see at top).

## Game Scripts

All scripts are written in JavaScript. Every script is called in the context of the match itself. Every script has always to return a match object which is then stored as a replacement for the match.

### The Match API

WIP

* addInvitation(invitation)
* acceptInvitation(invitation)
* declineInvitation(invitation)
* startGame()
* nextTurn()
* addMove(move)

All methods return the match itself so calls can be chained.

You can set errors on games using the ``errors`` field. Those will not be saved but exposed through the response of the API endpoint to the client that has sent the request.

### createMatch

This function is allowed to return **not** a game object but an empty object with just the ``errors`` property set. This way you can prevent matches from being created.

### addInvitation

Just accept an invitation:

```javascript
{
  addInvitation: function(invitation) {
    return this.addInvitation(invitation);
  }
}
```

Forbid the creation of an invitation:

```javascript
{
  addInvitation: function(invitation) {
    return this;
  }
}
```

### acceptInvitation

```javascript
{
  acceptInvitation: function(invitation) {
    return this.acceptInvitation(invitation);
  }
}
```

### declineInvitation

```javascript
{
  declineInvitation: function(invitation) {
    return this.declineInvitation(invitation);
  }
}
```

### nextTurn

```javascript
{
  nextTurn: function() {
    if (!this.started) {
      return this.startMatch();
    }
    return this.nextTurn();
  }
}
```

### newMove

```javascript
{
  newMove: function(move) {
    return this.addMove(move);
  }
}
```