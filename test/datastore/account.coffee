test.uses "Datastore.Account",
          "Datastore.Amount",
          "Datastore.Order"

describe 'Account', ->
  beforeEach ->
    @account = new Account()

  it 'should initialize with no balances', ->
    Object.keys(@account.balances).should.be.empty

  it 'should report a balance of zero for an unused currency', ->
    for c in Object.keys(Account.supported_currencies)
      @account.get_balance(c).toString().should.equal('0')

  it 'should raise an error if accessing an unsupported currency', ->
    expect =>
      @account.get_balance('fake')
    .to.throw('fake is not a supported currency')

    expect =>
      @account.credit('fake', amt(1))
    .to.throw('fake is not a supported currency')

  it 'should return a copy of a balance value', ->
    amount = amt Math.random()
    @account.credit('USD', amount)
    bal = @account.get_balance('USD')

    bal.should.equal_amount amount
    bal.should.not.equal @account.balances.USD

  it 'should be able to credit a balance', ->
    #amount = '3.141596281203071307479289982375230237197499234'
    amount = '3.1415962812030713'
    @account.credit('USD', amt(amount)).toString().should.equal(amount)

  it 'should be able to debit a balance', ->
    #amount = '5.398982919394105808134814845710341848259923589'
    amount = '5.3989829193838'
    @account.credit('USD', amt(amount))
    @account.credit('USD', amt(amount))
    @account.debit('USD', amt(amount)).toString().should.equal(amount)

  it 'should fail when trying to create an order with insufficient balance', ->
    expect =>
      @account.create_order('USD', amt('10'), 'BTC', amt('1'))
    .to.throw("Insufficient USD funds to place order")

  it 'should be able to create an order with sufficient balance', ->
    offer_amount = amt('10')
    receipt_amount = amt('1')

    @account.credit('USD', offer_amount)
    order = @account.create_order('USD', offer_amount, 'BTC', receipt_amount)
    order.should.be.an.instanceOf Order
    order.account.should.equal @account
    order.offered_currency.should.equal 'USD'
    order.offered_amount.should.equal offer_amount
    order.received_currency.should.equal 'BTC'
    order.received_amount.should.equal receipt_amount

    @account.get_balance('USD').toString().should.equal '0'

