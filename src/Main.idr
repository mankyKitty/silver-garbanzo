module Main

import Data.SOP

import JS
import Web.Dom
import Web.Html

%foreign "browser:lambda:x=>{document.body.innerHTML = x}"
prim__setBodyInnerHTML : String -> PrimIO ()

setBodyInnerHtml : HasIO io => String -> io ()
setBodyInnerHtml = primIO . prim__setBodyInnerHTML

domMain : JSIO ()
domMain = do
  btn <- createElement Button
  textContent btn .= "omg!"
  ignore $ (!body `appendChild` btn)

main : IO ()
main = do
  consoleLog "Hello from Idris2!"
  let n = S (S (S Z))
  consoleLog $ show n
  setBodyInnerHtml $ "<i>This part is written by main.idr. This next part is written using Idris2-dom:</i> " ++ "<p><tt>" ++ show n ++ "</tt><p>"
  runJS domMain
