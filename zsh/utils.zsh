is_wsl() {
    case "$(uname -r)" in
        *microsoft*|*Microsoft*) return 0 ;;
        *) return 1 ;;
    esac
}
