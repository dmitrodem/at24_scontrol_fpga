
# &#1057;&#1086;&#1076;&#1077;&#1088;&#1078;&#1072;&#1085;&#1080;&#1077;

1.  [Прошивка для платы Tang Primer 25k](#org01e7b55)
    1.  [Как собрать:](#org7ec1171)
    2.  [Как симулировать: Modelsim/Questasim](#org25acd14)
    3.  [Как симулировать: verilator/gtkwave](#orgeb0d5c2)


<a id="org01e7b55"></a>

# Прошивка для платы Tang Primer 25k

Файлы в проекте

1.  `filter.sv` &#x2013; сдвиговый регистр, используется для фильтрации
    дребезга входных сигналов.
2.  `top.sv` &#x2013; основная логика работы контроллера (обработка команд `I_C[2:0]`, `I_CLK`)
3.  `testbench.sv` &#x2013; простой тест, лучше бы его расширить различными сценариями работы
4.  `top.sdc` &#x2013; констрейнты для клока
5.  `top.cst` &#x2013; констрейнты для I/O
6.  `build_hw.sh`, `run.tcl` &#x2013; скрипты для сборки прошивки для ПЛИС (GOWIN IDE)
7.  `build_sim.sh` &#x2013; скрипт для сборки проекта в ModelSim/QuestaSim


<a id="org7ec1171"></a>

## Как собрать:

1.  установить GOWIN IDE
2.  поправить пути в `build_hw.sh` и запустить его либо напрямую
    запустить `source run.tcl` из IDE или `gw_sh`
3.  получившаяся прошивка располагается в
    `impl/pnr/at24_scontrol.fs`. На ПЛИС заливать либо с помощью
    программатора GOWIN, либо с помощью `openFPGALoader`:

    openFPGALoader -b tangprimer25k impl/pnr/at24_scontrol.fs


<a id="org25acd14"></a>

## Как симулировать: Modelsim/Questasim

1.  Убедиться, что Modelsim/Questasim находится в `PATH` (команды vlog, vlib, vmap, vsim)
2.  Выполнить скрипт `build_sim.sh` &#x2013; он создаст `Makefile` для последующих перезапусков
3.  Запустить GUI командой `vsim -voptargs=+acc testbench`
4.  В GUI добавить сигналы в БД командой `log -r /*`
5.  Добавить интересующие сигналы в waveform window
6.  Запустить симуляцию командой `run -all`


<a id="orgeb0d5c2"></a>

## Как симулировать: verilator/gtkwave

1.  Собрать проект командой

    verilator --binary -sv src/filter.sv src/top.sv src/testbench.sv --top-module testbench --trace --trace-structs

1.  Запустить симуляцию: `./obj_dir/Vtestbench`
2.  Просмотреть получившийся файл `waveform.vcd` программой `gtkwave`

