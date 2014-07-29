// Playground - noun: a place where people can play

import UIKit

class WordRemeberer
{
    var words:Array<String> = Array<String>()
    
    //call this to know if the word was remembered
    func knowsWord(aWord:String) -> Bool
    {
        if (find(words, aWord))
        {
            return true
        }
        return false
    }
    
    //call this to learn a word
    func learnWord(aWord:String)
    {
        words += aWord
    }
    
}

let amazingCrescan = WordRemeberer()

amazingCrescan.knowsWord("hah")
amazingCrescan.learnWord("Google")
amazingCrescan.knowsWord("Google")
