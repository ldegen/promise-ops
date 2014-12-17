
Promise = require("promise")

exports.ifP=(i,t,e)->
  Promise.from(i).then (truth)->
    if truth and typeof t == "function" then t(truth)
    else if typeof e == "function" then  e(truth)

exports.mapP=(arrP,fP)->
  Promise.all(arrP,fP).then ([arr,f])->
    Promise.all(arr).then (elms)->
      Promise.all elms.map(f)



exports.composeP=(funs)->
  cmp = (f,g)->
    (x)->Promise.from(x).then(g).then(f)
  funs.reduceRight (prev,cur)->cmp(cur,prev)

exports.pipeP= (val,funs)->
  cmp = (prev,cur)->
    Promise.from(prev).then cur
  funs.reduce cmp,val

exports.eachP = (arr0,fun)->
  Promise.from(arr0).then (arr)->
    arr.reduce (prev0,cur0)->
      Promise.from(prev0).then (prev)->
        Promise.from(cur0).then (cur)->
          Promise.from(fun(cur)).then (fcur)->
            nextPrev=[].concat prev,fcur
            nextPrev
    , []

exports.reduceP = (arr0, fun0, start0)->
  argc = arguments.length
  Promise.all([arr0,fun0,start0]).then ([arr,fun,start])->
    funfun = (prev0,cur0)->
      Promise.all([prev0,cur0]).then ([prev,cur])->
        fun(prev,cur)
    if argc>2
      arr.reduce(funfun,start)
    else
      arr.reduce(funfun)

exports.whileP = whileP=(guard,statement,value0)->
  Promise.from(value0).then (current)->
    Promise.from(guard(current)).then (g)->
      if g
        Promise.from(statement(current)).then (next)->whileP( guard,statement,next)
      else
        current

