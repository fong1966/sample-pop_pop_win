abstract class GameManager {
  final int _width, _height, _mineCount;
  final GameStorage _gameStorage = new GameStorage();

  Game _game;
  GlobalId _updatedEventId;
  GlobalId _gameStateChangedId;
  int _setIntervalId;

  GameManager(this._width, this._height, this._mineCount) {
    newGame();
  }

  Game get game => _game;

  EventRoot<EventArgs> get highScoreUpdated => _gameStorage.highScoreUpdated;

  int get highScore => _gameStorage.getHighScore(_width, _height, _mineCount);

  void newGame() {
    if(_updatedEventId != null) {
      assert(_game != null);
      assert(_gameStateChangedId != null);
      _game.updated.remove(_updatedEventId);
      _game.stateChanged.remove(_gameStateChangedId);
      _gameStateChanged(GameState.reset);
    }
    final f = new Field(_mineCount, _width, _height);
    _game = new Game(f);
    _updatedEventId = _game.updated.add(gameUpdated);
    _gameStateChangedId = _game.stateChanged.add(_gameStateChanged);
  }

  void gameUpdated(args);

  void resetScores() {
    _gameStorage.reset();
  }

  void _click(int x, int y, bool alt) {
    final ss = _game.getSquareState(x, y);

    if(alt) {
      if(ss == SquareState.hidden) {
        _game.setFlag(x, y, true);
      } else if(ss == SquareState.flagged) {
        _game.setFlag(x, y, false);
      } else if(ss == SquareState.revealed) {
        _game.reveal(x, y);
      }
    } else {
      if(ss == SquareState.hidden) {
        _game.reveal(x, y);
      }
    }
  }

  void updateClock() {
    if(_setIntervalId == null && _game.state == GameState.started) {
      _setIntervalId = window.setInterval(_doClock, 1000);
    } else if(_setIntervalId != null && _game.state != GameState.started) {
      window.clearInterval(_setIntervalId);
      _setIntervalId = null;
    }
  }

  // DARTBUG: work around for http://code.google.com/p/dart/issues/detail?id=3197
  void _doClock() {
    updateClock();
  }

  bool get _canClick {
    return _game.state == GameState.reset ||
        _game.state == GameState.started;
  }

  void _gameStateChanged(GameState newState) {
    _gameStorage.recordState(newState);
    if(newState == GameState.won) {
      final newHighScore = _gameStorage.updateHighScore(_game);
    }
    updateClock();
  }
}
