---
tags:
- go
- open-source
- compatibility
date: 2026-09-04T10:00:00+02:00
title: Compatibility manifesto
description: Why compatibility costs belong to maintainers, old APIs should keep working and major versions should remain independent lines
slug: compatibility-manifesto
---

I work on many things, but primarily on [remark42](https://github.com/umputun/remark42) and the [go-pkgz](https://github.com/go-pkgz) libraries. I follow the same compatibility rules everywhere: whatever shipped keeps working. I sometimes break my own rules, but these are the principles I have followed over the years.

The cost of a break is never paid by the person who causes it.

<!--more-->

I planned originally to post the manifesto in full on [my GitHub page](https://github.com/paskal), but it turned out to be too long for that.

## Everything that shipped keeps working

Endpoints are added, not withdrawn. remark42 has served `/api/v1` since June 2018 and still does at v1.16.4, with no v2 and nothing removed that anyone was using. A response may gain fields; it does not lose them.

Command-line options work the same way. Once an option ships in a tagged release it keeps working, and the program reports its deprecation at start-up. remark42 currently carries 15 deprecated option names, the oldest of them deprecated in v1.5 in January 2020 and still working unchanged today. When an old and a new name are both given with different values, the program logs an error and uses the new one instead of guessing.

This holds even when the feature behind an option is gone for good. Twitter authentication stopped working when Twitter withdrew the API behind it, and remark42 still declares `auth.twitter.cid` and `auth.twitter.csec`, marked as deprecated and non-functional, so a server started from an old configuration comes up with a warning instead of failing on an unknown flag.

Superseded entry points in the libraries are kept the same way: `DeDupBig` in go-pkgz/stringutils is a deprecated wrapper around its replacement, `sess` in go-pkgz/auth is a query-parameter alias honoured since the beginning, and `DisableNotFoundHandler()` in go-pkgz/routegroup is a no-op retained purely for API compatibility. When a fix would change behaviour someone may have built on, it ships as documentation and better error reporting instead of a behaviour change. This should sound familiar to anyone who has written Go; the Go 1 compatibility promise applies the same idea to its standard library.

## Libraries build on the oldest Go version that still compiles them

The `go` directive in a library is a promise to everyone who cannot move: people on old architectures, on old operating systems, on a build host nobody is allowed to touch. Raising it without a strong reason improves nothing for them and costs them the library, so dependencies are refreshed regularly, but anything demanding a newer Go is skipped and named instead of being allowed to drag the directive up. Among the go-pkgz libraries, expirable-cache v1 still builds on Go 1.14 (EOL 2021) and v2 on 1.18 (EOL 2023), email and fileutils on 1.19 (EOL 2023), lgr and lcw on 1.21 (EOL 2024), syncs on 1.22 (EOL 2025).

Usually a new Go release brings enough to be worth the directive going up, and it goes up. The exception is a release with a single item worth having, which on its own does not justify the move; then that item goes behind a build tag and the minimum stays where it is. go-pkgz/rest ships its CSRF protection twice for exactly that reason: one file under `//go:build go1.25` wraps the standard library's `http.CrossOriginProtection`, another under `//go:build !go1.25` provides a handwritten equivalent, so the module still builds on 1.24 (EOL 2026).

## A major version is a separate line, not an upgrade

A new major exists because an interface could not be kept, and for no other reason. In go-pkgz/auth it was an upstream change surfacing in the library's own signatures: v1 exposes `golang-jwt/jwt` v3 types and therefore still depends on v3, while v2 exposes only v5. In expirable-cache v2 and lcw v2 it was generics, which the old signatures could not express at all. Tidier naming, a nicer interface or a wish to delete old code are not reasons.

So v2 is not an improved v1. It is the same library with the one change that could not be avoided, and staying on v1 is a legitimate permanent choice instead of a migration someone is putting off. While both lines are alive they are released together: go-pkgz/auth tagged v1.26.0 and v2.2.0 on the same day, and the pairing holds back through v1.25.7 with v2.1.7 and v1.25.6 with v2.1.6.

## Where this stops

A line can go quiet. expirable-cache is the clearest case: v1 is simply the slower pre-generics version, and v2 has an interface that does not match the one hashicorp/golang-lru cache established, despite getting everything else right. v3 fixed that mismatch, and it is the only line now developed; v1 and v2 have had no release since September 2022 and the project README says so plainly instead of implying support that is not there. Releasing both lines together is what I do while both are alive, not a guarantee that every line stays alive forever.

And if the only available fix for a security problem is a change in behaviour, the fix wins. All of the above is about who absorbs the cost of a change, not about refusing to make one.
