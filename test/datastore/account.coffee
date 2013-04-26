test.uses "Datastore.Account",
          "Datastore.Amount"

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

  xit 'should return a copy of a balance value'

  it 'should be able to credit a balance', ->
    amount = '3.141596281203071307479289982375230237197499234'
    @account.credit('USD', amt(amount)).toString().should.equal(amount)

  it 'should be able to debit a balance', ->
    amount = '5.398982919394105808134814845710341848259923589'
    @account.credit('USD', amt(amount))
    @account.credit('USD', amt(amount))
    @account.debit('USD', amt(amount)).toString().should.equal(amount)

  xit 'should be able to create an order with sufficient balance'
  xit 'should fail when trying to create an order with insufficient balance'

