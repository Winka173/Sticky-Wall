# Production access form: draft answers

Draft for the form Play Console shows after 14 days of closed testing
(*Test and release → Production → Apply for production*, Vietnamese console:
*Kiểm thử và phát hành → Phát hành công khai → Đăng ký quyền truy cập*).
Saved on 2026-11-11; the closed test does not have its 14 days yet.

Every answer below describes what really happened. Before sending, check the
lines marked **[owner]**, and add anything that changes before then (a new
version, more feedback). Do not paste the testing provider's sample answers:
they claim changes the app did not get, and Google compares the form with
the app.

Testers' report: `sticky_feedback.pdf` (Testers Community), received
2026-11-11. It found no crashes or bugs and suggested: store text with
search keywords, screenshots that show the features, a walkthrough for new
users, and an exit confirmation.

---

**1. How did you recruit users for your closed test?**

We used a paid testing provider (Testers Community), whose testers used the
app on a range of devices and Android versions and sent a written report.
**[owner: add it if you also invited friends, family or other users.]**

**2. How easy was it to recruit testers for your app?**

**[owner: pick what matches your experience.]** Through the provider it took
little effort.

**3. Describe the engagement you received from testers during your closed
test.**

Testers installed the closed-testing builds as we released them (1.6.1 to
1.6.4 during the test) and used the main parts of the app: notes on the
wall, checklists, reminders, boards, templates and settings. They reported
no crashes or functional bugs. Their written report focused on how new users
discover the app and its features: the store listing text, the screenshots,
onboarding and leaving the app by accident.

**4. Provide a summary of the feedback that you received from testers.
Include how you collected the feedback.**

Feedback came as a written report from the testing provider, alongside the
app's own "Send feedback" email link in Settings and our checks of Android
vitals in Play Console. Testers found the app stable on every device they
tried. They suggested:
- a store description that uses the words people search for;
- screenshots that show the features, with captions;
- guidance for new users;
- protection against closing the app by accident.

**5. Who is the intended audience for your app?**

People who like paper notes and pin-boards and want the same on their phone:
students planning study and exams, families keeping lists and reminders,
people planning trips or keeping photo memories, and anyone who organises
visually (to-do lists, Kanban boards, vision boards). The app is in English
and Vietnamese.

**6. Describe how your app provides value to the users.**

Sticky Wall puts notes on a wall that looks and behaves like a real one.
- **Notes:** seven kinds of notes (text, checklists, links, drawings, photo
  prints, tape labels, voice notes), dragged, turned, stacked and tied
  together with yarn.
- **Reminders:** set in one tap.
- **Getting started:** 45 board templates and 37 themes.
- **On the home screen:** a home-screen widget.
- **Privacy:** it works offline with no account, no ads and no tracking.
  Notes stay on the phone, with optional sync through the user's own Google
  Drive.
- **Price:** everything essential is free. Pro is a one-time purchase, not a
  subscription.

**7. How many installs do you expect your app to have in your first year?**

**[owner: pick.]** Suggested: 1,000 – 10,000. It is a new app with no
advertising budget, so a modest estimate is more credible than 10k–100k.

**8. What changes did you make to your app based on what you learned during
your closed test?**

- **Store listing:**
  - rewrote the title and descriptions around the terms people search
    (sticky notes, notes widget, reminders, to-do list; Vietnamese: giấy nhớ,
    ghi chú, nhắc việc, việc cần làm);
  - replaced the screenshots with captioned ones that show each main feature,
    in English and Vietnamese, including tablet screenshots;
  - made a new feature graphic.
- **Leaving by accident:** Back on the main screen now asks for a second
  press before leaving ("Press Back again to leave"). It can be turned off in
  Settings. Notes are saved automatically, so nothing is lost either way.
- **New users:** the first-run guide shows each gesture with an animated hand,
  and offers Skip and "Do it for me". It is now named in the listing and the
  screenshots, so people know it is there. Long-pressing the app icon now
  offers quick ways in: a new note, a to-do list or a voice note.
- **Other improvements during the test:**
  - links in notes;
  - clearer board tabs that stay readable on every wall, with a tray for
    dropping notes on any board;
  - a board list on tablets;
  - keyboard shortcuts and right-click menus for tablets and Chromebooks;
  - a rating prompt that appears only after the app has been useful;
  - privacy policy and terms pages linked in the app.

**9. How did you decide that your app is ready for production?**

- **Stability:** the closed test showed no crashes or functional bugs across
  the testers' devices, and Android vitals stayed clean.
- **Feedback:** every suggestion from testers was handled in the app or the
  listing.
- **Our own checks:**
  - the app passes its automated test suite (over 400 tests);
  - it was checked on phone and tablet screen sizes;
  - the privacy policy, terms of service and data safety form are complete
    and match what the app does.

**10. What did you do differently this time?**

**[owner: only if this is a second application.]** If it is the first, leave
this out or say it is the first application.

---

## When you send it

1. Check that the newest closed-testing version is the one described above
   (`python tool/play.py codes`).
2. Fill in the **[owner]** lines.
3. Keep the answers in English. Google reviews them in English.
