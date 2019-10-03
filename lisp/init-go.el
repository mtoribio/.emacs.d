;; init-go.el --- Initialize Golang configurations.	-*- lexical-binding: t -*-

;; Copyright (C) 2019 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; URL: https://github.com/seagle0128/.emacs.d

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;

;;; Commentary:
;;
;; Golang configurations.
;;

;;; Code:

;; Golang
(use-package go-mode
  :functions (go-packages-gopkgs go-update-tools)
  :bind (:map go-mode-map
         ([remap xref-find-definitions] . godef-jump)
         ("C-c R" . go-remove-unused-imports)
         ("<f1>" . godoc-at-point))
  :config
  ;; Env vars
  (with-eval-after-load 'exec-path-from-shell
    (exec-path-from-shell-copy-envs '("GOPATH" "GO111MODULE" "GOPROXY")))

  ;; Format with `goimports' if possible, otherwise using `gofmt'
  (when (executable-find "goimports")
    (setq gofmt-command "goimports"))
  (add-hook 'before-save-hook #'gofmt-before-save)

  ;; Install or update tools
  (defvar go--tools '("golang.org/x/tools/gopls"
                      "golang.org/x/tools/cmd/goimports"
                      "golang.org/x/tools/cmd/gorename"

                      ;; "github.com/rogpeppe/godef"
                      "github.com/go-delve/delve/cmd/dlv"
                      "github.com/josharian/impl"
                      "github.com/cweill/gotests/..."
                      "github.com/fatih/gomodifytags"
                      "github.com/davidrjenni/reftools/cmd/fillstruct"
                      "github.com/golangci/golangci-lint/cmd/golangci-lint")
    "All necessary go tools.")

  (defun go-update-tools ()
    "Install or update go tools."
    (interactive)
    (unless (executable-find "go")
      (user-error "Unable to find `go' in `exec-path'!"))

    (message "Installing go tools...")
    (dolist (pkg go--tools)
      (set-process-sentinel (start-process "go-tools" "*go-tools*" "go" "get" "-u" "-v" pkg)
                            (lambda (proc _)
                              (let ((status (process-exit-status proc)))
                                (if (= 0 status)
                                    (message "Installed %s" pkg)
                                  (message "Failed to install %s: %d" pkg status)))))))

  (unless (executable-find "gopls")
    (go-update-tools))

  ;; Misc
  (use-package go-dlv)
  (use-package go-fill-struct)
  (use-package go-impl)
  (use-package go-rename)

  ;; Install: go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
  (use-package flycheck-golangci-lint
    :if (executable-find "golangci-lint")
    :after flycheck
    :defines flycheck-disabled-checkers
    :hook (go-mode . (lambda ()
                       "Enable golangci-lint."
                       (setq flycheck-disabled-checkers '(go-gofmt
                                                          go-golint
                                                          go-vet
                                                          go-build
                                                          go-test
                                                          go-errcheck))
                       (flycheck-golangci-lint-setup))))

  (use-package go-tag
    :bind (:map go-mode-map
           ("C-c t" . go-tag-add)
           ("C-c T" . go-tag-remove))
    :config (setq go-tag-args (list "-transform" "camelcase")))

  (use-package go-gen-test
    :bind (:map go-mode-map
           ("C-c C-t" . go-gen-test-dwim)))

  (use-package gotest
    :bind (:map go-mode-map
           ("C-c a" . go-test-current-project)
           ("C-c m" . go-test-current-file)
           ("C-c ." . go-test-current-test)
           ("C-c x" . go-run))))

;; Local Golang playground for short snippets
(use-package go-playground
  :diminish)

(provide 'init-go)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-go.el ends here
