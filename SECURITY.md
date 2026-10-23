# Security policy

## Reporting a vulnerability

Please report security problems privately, using [GitHub's private vulnerability reporting] (also accessible via the
**Security** tab). 

Please do not open a public issue or pull request for a security problem.

A useful report says:

- what the problem is
- where it is (a URL or file and line)
- and how to reproduce it

A proof of concept helps. Only the maintainer and you can see the report, and we can discuss and fix it there before anything is made public.

## What to expect

This is a spare-time project maintained by one person, so response times are best effort. 

You will get an acknowledgement and an assessment, and if the report is valid it will be fixed and deployed. 

You will be credited in the published advisory if you want to be.

## Scope and supported versions

Only the current code on the `main` branch, and the deployment of it at <https://twenty-five-ten.herokuapp.com/>, are supported. 

Older commits do not receive fixes.

Problems in the platform the app runs on (for example Heroku itself) should be reported to that vendor.

## Data

The app stores only what participants choose to submit, and deletes everything 30 days after it was created. See the privacy page in the app for details.

[GitHub's private vulnerability reporting]: https://github.com/heathd/twentyfiveten/security/advisories/new