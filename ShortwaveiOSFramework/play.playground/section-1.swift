// Playground - noun: a place where people can play

import UIKit

var name = "Alonso"



class ContentType {
    
}

class Gif {
    
    let src: String
    
    init(fromValues src: String){
        self.src = src
    }
    
    class func parseJson(src: String) -> Gif? {
        if false{
            return Gif(fromValues: src)
        } else {
            return nil
        }
    }
    
    init(fromDict dict: Dictionary<String,String>){
        println(dict)
        self.src = "hi!"
    }
    
}

var g = Gif(fromValues: "hi")

g

if let a : Gif = Gif.parseJson("wat")?{
    a
} else {
    var err = "error"
}

//let a : Gif = Gif.parseJson("muhaha")!

var a = Gif.parseJson("haha")

a


//
//
//
//var a : Gif?
//
//a = Gif.parseJson("hi")
//
//a