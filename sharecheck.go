package main

// The host dialog's shared file system helpers (SPEC F2c): Check share
// runs internal/sharecheck's script on the agent host over ssh with the
// dialog's values (saved or not); VM share setup… writes the steps that
// share the local prefix into a KVM/libvirt VM.

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"session-workbench/internal/remote"
	"session-workbench/internal/session"
	"session-workbench/internal/sharecheck"
	"session-workbench/internal/xfer"
)

// CheckShare checks that remotePrefix on target is a mounted share holding
// the same entries as localPrefix here ("" local prefix: not compared).
func (a *App) CheckShare(target, localPrefix, remotePrefix string) (sharecheck.Result, error) {
	target, remotePrefix = strings.TrimSpace(target), strings.TrimSpace(remotePrefix)
	if target == "" {
		return sharecheck.Result{}, errors.New("give the ssh target first")
	}
	if remotePrefix == "" {
		return sharecheck.Result{}, errors.New("give the remote prefix to check (without one, paths are the same on both machines)")
	}
	if err := remote.CheckRemotePath(remotePrefix); err != nil {
		return sharecheck.Result{}, errors.New("the remote prefix must be absolute or start with ~/")
	}
	var local []string
	localPrefix = strings.TrimSpace(localPrefix)
	if localPrefix != "" {
		var err error
		if local, err = sharecheck.LocalNames(session.ExpandHome(localPrefix)); err != nil {
			return sharecheck.Result{}, fmt.Errorf("reading the local prefix: %w", err)
		}
	}
	ctx, cancel := context.WithTimeout(a.ctx, 60*time.Second)
	defer cancel()
	out, code, stderr, err := xfer.Run(ctx, target, sharecheck.Script(remotePrefix), nil)
	if err != nil {
		return sharecheck.Result{}, err
	}
	if code != 0 {
		return sharecheck.Result{}, fmt.Errorf("ssh to %s: %s", target, strings.TrimSpace(stderr))
	}
	return sharecheck.Evaluate(string(out), local, localPrefix, remotePrefix), nil
}

// VMShareGuide writes the libvirt XML and the mount commands that share
// localPrefix into a VM mounting it at remotePrefix; driver virtiofs or 9p.
func (a *App) VMShareGuide(localPrefix, remotePrefix, driver string) sharecheck.Guide {
	return sharecheck.MakeGuide(session.ExpandHome(strings.TrimSpace(localPrefix)), strings.TrimSpace(remotePrefix), driver, os.Getuid())
}
