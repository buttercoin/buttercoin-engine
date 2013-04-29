test.uses "Datastore.DataStore",
          "Datastore.BalanceSheet",
          "Datastore.SuperMarket",
          "Datastore.Amount",
          "Datastore.Account",
          "Datastore.Order"

# WARNING: DataStore is inherently SYNCHRNOUS and NON-REENTRANT
# No callbacks in here!

describe 'DataStore', ->
  setup_mocking()

  beforeEach ->
    @balancesheet = @mockify(new BalanceSheet())
    @supermarket = @mockify(new SuperMarket())
    @datastore = new DataStore(@balancesheet.object, @supermarket.object)

  describe '.deposit', ->
    it 'cannot be called with Javascript Number amounts as they are inherently innacurate', (done) ->
      expect =>
        @datastore.deposit
          account: 'Peter'
          currency: 'USD'
          amount: 50
      .to.throw('Only string amounts are supported in order to ensure accuracy')
      done()

    it 'should be able to credit an account', ->
      deposit_amount = '50'
      currency = 'USD'
      account_name = 'Peter'
      account = @mockify(new Account())

      @balancesheet.expects('get_account').once().withArgs(account_name).returns(account.object)
      account.expects('credit').once().withArgs(currency).returns(amt deposit_amount)

      @datastore.deposit
        account: account_name
        currency: 'USD'
        amount: deposit_amount
      .toString().should.equal(deposit_amount)

    it 'should be able to place an order with sufficient funds', ->
      account_name = 'Peter'
      account = @mockify(new Account())
      offer_amount = amt '10'
      receipt_amount = amt '1'
      created_order = new Order('USD', offer_amount, 'BTC', receipt_amount)

      @balancesheet.expects('get_account').once().withArgs(account_name).returns(account.object)
      account.expects('create_order').once().withArgs('USD', offer_amount, 'BTC', receipt_amount).returns(created_order)
      @supermarket.expects('route_order').once().withArgs(created_order)

      @datastore.place_order
        account: account_name
        offered_currency: 'USD'
        offered_amount: offer_amount
        received_currency: 'BTC'
        received_amount: receipt_amount
      
      
