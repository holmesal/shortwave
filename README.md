shortwave
=======

hacking on earshot
---

write good code and commit/push often to keep things from getting out of sync.

don't hesitate to nuke the firebase - there's no better way to test the signup flow and it's often unavoidable if the user model changes.

next steps
---

1. ~~Hook up the bottom "message" input - mimic the messages UI where the text input "rides" the keyboard up when you focus on it. Embed the table view and the text input in a user-disabled scroll view, and scroll it upwards under the navbar on select? Right now everything is hooked up through the "compose" modal triggered by the button on the upper right.~~ (done)
2. ~~Design a better signup flow. All of the elements are there but the presentation could be much better. Also need to error-check specific inputs - only one-word usernames should be allowed, certain characters, etc.~~ (removed)
3. ~~Generate default user images based on a hash of the username - reference [identicons](http://en.wikipedia.org/wiki/Identicon) and [this github article](https://github.com/blog/1586-identicons) for inspiration.~~ (removed)
4. ~~Figure out how to show what users are in range in a compact way that can be expanded on demand. Right now it's a grey block collection view, with the idea that people will scroll sideways to see the full number, or click to open a fullscreen overlay. The problem is that the space feels a little limited on an iPhone 5, and it's only gonna be worse on a 4s (the oldest supported device). Maybe roll it into the placeholder for the bottom text field?~~
5. ~~Get smarter about auto-scrolling to the bottom - if the user is scrolling backwards and a new message appears, they shouldn't be pulled back to the bottom. Probably do this based on a timeout, where if the feed position has been stagnant for more than a few seconds, yank-downs apply. Also show a small bar on the bottom if there are unread messages down there.~~
~~6. Recognize embedded image URLs and replace them with the fetched image.~~ (descoped)
7. ~~Expand or shrink table view cells to fit the content inside. Right now it just cuts off at one line.~~
8. ~~Scrolling all the way up in the table view produces a weird empty white space.~~
9. ~~Should have a "pull-to-load-older" functionality at the top of the table view.~~
10. ~~Figure out the whole push-notification-when-you-get-a-message thing.~~
11. ~~Upload user-selected images to s3, yo.~~ (not needed)
12. Show a lightweight popup on the right if you're scrolled up and new messages appear down there
13. Fade out messages from people no longer in range.
14. ~~Hook up collection view at the top.~~


crazy features (next iteration)
---
1. Hook up (hubot)[http://hubot.github.com/].
2. Allow deeplinks into other apps or twitter card-like functionality.
3. Attach a file or folder from dropbox.
