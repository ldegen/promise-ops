require "promise-matchers"
describe "Promise Utility Functions",->
  Promise = require("promise")

  utils = require('../src/utils-p')


  describe "The ifP()-Function", ->

    expect42 = (done)->
      (result)->
        expect(result).toEqual(42)
        done()

    it "promises the result of calling the second argument if the first argument is truthy", (done)->
      utils.ifP(true, -> 42).then expect42(done)
    it "promises the result of calling third argument if the fist argument is falsy", (done)->
      utils.ifP(false, undefined,-> 42).then expect42(done)
    it "transparently unwrapps the first argument if it is a promise", (done)->
      utils.ifP(Promise.from(false),undefined,->42).then expect42(done)
    it "also allows the callbacks to return promises", (done)->
      utils.ifP(Promise.from(false),undefined,->Promise.from(42)).then expect42(done)
    it "passes the condition value when calling the callbacks", (done)->
      utils.ifP(Promise.from(21), (c)->2*c).then expect42(done)


  describe "The mapP()-Function", ->

    double=(x)->2*x
    expect246 =(done)->
      (result)->
        expect(result).toEqual([2,4,6])
        done()

    it "does what Array.prototype.map() does, but returns a Promise", (done)->
      utils.mapP([1,2,3],double).then expect246(done)
    it "transparently unwraps the first argument if it is a Promise", (done) ->
      utils.mapP(Promise.from([1,2,3]),double).then expect246(done)
    it "transparently unwraps array elements if they are Promises", (done) ->
      utils.mapP(Promise.from([1,Promise.from(2),3]),double).then expect246(done)
    it "transparently unwraps the second argument if it is a Promise", (done) ->
      utils.mapP([1,2,3],Promise.from(double)).then expect246(done)

  describe "The composeP()-Function",->
    it "composes functions, creating a function that returns a promise", (done)->
      h = (x)-> x+"h"
      g = (x)-> x+"g"
      f = (x)-> x+"f"
      fgh=utils.composeP([f,g,h])
      fgh("").then (result)->
        expect(result).toEqual("hgf")
        done()

    it "transparently unwrapps promised values", (done)->
      h = (x)-> x+"h"
      g = (x)-> Promise.from(x+"g")
      f = (x)-> x+"f"
      fgh=utils.composeP([f,g,h])
      fgh(Promise.from("")).then (result)->
        expect(result).toEqual("hgf")
        done()


  describe "The pipeP()-Function",->
    it "pipes a value through a sequence of functions, yielding a promise", (done)->
      h = (x)-> x+"h"
      g = (x)-> x+"g"
      f = (x)-> x+"f"

      utils.pipeP("",[f,g,h]).then (result)->
        expect(result).toEqual("fgh")
        done()

    it "transparently unwrapps promised values", (done)->
      h = (x)-> x+"h"
      g = (x)-> Promise.from(x+"g")
      f = (x)-> x+"f"
      utils.pipeP(Promise.from(""),[f,g,h]).then (result)->
        expect(result).toEqual("fgh")
        done()

  describe "The eachP-Function",->
    it "like mapP but in strict sequencial order", (done)->
      trace=[]
      delay =(millis)->
        new Promise (resolve)->
          setTimeout resolve,millis
      f=(x)->
        trace.push("s"+x)
        delay(x).then ()->
          trace.push("r"+x)
          x*x
      expect(utils.eachP([200,50,0],f)).toHaveBeenResolvedWith done, (result)->
        expect(trace).toEqual(["s200","r200","s50","r50","s0","r0"])
        expect(result).toEqual([40000,2500,0])

    it "resolves the returned promise with an array containing the return values",(done)->
      f=(x)->x*x
      utils.eachP([1,2,3],f).then (r)->
        expect(r).toEqual([1,4,9])
        done()
    it "also works if the first argument is a promise yielding an array",(done)->
      delay =(millis)->
        new Promise (resolve)->
          setTimeout resolve,millis
      r=[]
      f=(x)->
        delay(x)
        r.push(x)
      utils.eachP(Promise.from([200,50,0]),f).then (result)->
        expect(r).toEqual([200,50,0])
        done()
    it "keeps calm and easy even if the array contains promises",(done)->
      delay =(millis)->
        new Promise (resolve)->
          setTimeout resolve,millis
      r=[]
      f=(x)->
        delay(x)
        r.push(x)
      utils.eachP(Promise.from([200,Promise.from(50),0]),f).then (result)->
        expect(r).toEqual([200,50,0])
        done()

    describe "The reduceP-Function",(done)->
      it "works like Array.prototype.reduceP", (done)->
        trace=[]
        sum = (prev,cur) ->
          trace.push "#{prev}+#{cur}"
          prev+cur
        expect(utils.reduceP [1,2,3], sum).toHaveBeenResolvedWith done, (r)->
          expect(r).toBe(6)
          expect(trace).toEqual [
            "1+2",
            "3+3"
          ]
      it "can take an extra start value", (done)->
        trace=[]
        sum = (prev,cur) ->
          trace.push "#{prev}+#{cur}"
          prev+cur
        expect(utils.reduceP [1,2,3], sum,4).toHaveBeenResolvedWith done, (r)->
          expect(r).toBe(10)
          expect(trace).toEqual [
            "4+1",
            "5+2",
            "7+3"
          ]

    it "transparently unwrapps promise elements in the array", (done)->
      sum = (a,b)->a+b
      expect(utils.reduceP [1,Promise.from(2),3], sum).toHaveBeenResolvedWith done, (r)->
        expect(r).toBe(6)

    it "deals with promises returned from the aggregator function", (done)->
      sum = (a,b)-> Promise.from(a+b)
      expect(utils.reduceP [1,2,3], sum).toHaveBeenResolvedWith done, (r)->
        expect(r).toBe(6)
    
    describe "The whileP-Function",->
      it "executes statement while guard evaluates to something truthy", (done)->
        negative = createSpy("guard").andCallFake (i)->i<0
        increment = createSpy("statement").andCallFake (i)->i+1

        p = utils.whileP negative,increment,-3

        expect(p).toHaveBeenResolvedWith done,(i)->
          expect(i).toBe 0
          expect(negative.calls.length).toBe 4
          expect(increment.calls.length).toBe 3

