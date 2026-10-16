FROM bgauduch/cod2server:8.1.1-1_3_nodelay_va_loc-ibuddieat

HEALTHCHECK --interval=5s --timeout=2s --start-period=30s --retries=3 \
  CMD ["/bin/sh", "-c", "grep -qx cod2_lnxded /proc/1/comm && test -e /home/${SERVER_USER}/.callofduty2/main/games_mp.log"]