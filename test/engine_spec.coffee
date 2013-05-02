test.uses "TradeEngine"

describe "TradeEngine", ->
  setup_mocking()

  beforeEach ->
    @engine = new TradeEngine()
    @mockify 'engine'

  it "should throw an error if given an invalid operation", ->
    expect =>
      @engine.execute_operation(null)
    .to.throw "Invalid Operation"

    expect =>
      @engine.execute_operation({})
    .to.throw "Invalid Operation"

  it "should throw an error if given an unknown operation", ->
    expect =>
      @engine.execute_operation(kind: "fake op")
    .to.throw "Unknown Operation"

  xit "should handle ADD_DEPOSIT operations"
