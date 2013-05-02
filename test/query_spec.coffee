test.uses "QueryInterface",
          "Datastore.BalanceSheet",
          "Datastore.Amount",
          "Datastore.Account"

describe "QueryInterface", ->
  setup_mocking()

  beforeEach ->
    @balancesheet = @mockify(new BalanceSheet())
    @qi = new QueryInterface(@balancesheet.object)

    @mockify 'qi'

  it 'should provide an account balance', ->
    account_id = 'Fred'
    acct = @mockify(new Account())
    balances = {}

    @balancesheet.expects('get_account').once().withArgs(account_id).returns(acct.object)
    for c, v of Account.supported_currencies
      if v
        balances[c] = amt Math.random()
        acct.expects('get_balance').once().withArgs(c).returns(balances[c])

    for c, v of @qi.get_balances(account_id)
      balances[c].should.equal_amount v
      delete balances[c]

    Object.keys(balances).length.should.equal 0

