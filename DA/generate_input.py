import pandas as pd
import numpy as np
import click

def gen_init_states(base, parameters, mu, sigma, num=100, sign=None):

    init = base.loc[np.repeat(base.index.values, num)].reset_index(drop=True)
    for p in parameters:
        s = sign
        init[p] = np.random.normal(mu, sigma, size=init.shape[0])
        if p == 'PDYN':
            s = 'pos'
        if s == 'pos':
            init[p] = init[p].apply(lambda x: abs(round(x*100)/100)+0.1)
        elif s == 'neg':
            init[p] = init[p].apply(lambda x: -abs(round(x*100)/100)+0.1)
        else:
            init[p] = init[p].apply(lambda x: round(x*100)/100)
                
    return init

@click.command()
@click.argument('column', type=str, nargs=-1)
@click.argument('mu', type=float, default=0)
@click.argument('sigma', type=float, default=0.05)
@click.argument('amount', type=int, default=100)
@click.option('--sign', type=bool, default=False)
def main(column, mu, sigma, amount, sign):
    '''Generates Tsyganenko inputfile named TA15_input
    Generates inputfile useable by model TA15. 
    It varies the value in column given, by picking randomly from a gaussian distribution
    The other values remain fixed.
    Input:
        column: name of variable to be varied 
        mu: mean value of the gaussian distribution
        sigma: standard deviation of gaussian distribution
        amount: Total number of inputs - size of the ensemble
        sign: Set all random values to sign of mu if true
    Output:
        file named TA15_output, useable by model TA15.
    '''
    columns = ['PDYN', 'B0y', 'B0z', 'XIND']

    for c in column:
        assert c in columns, "Error, unknown variable {}. Known variables: {}".format(c, columns)

    base = pd.DataFrame(columns=columns, 
                        data=[[3.0, 1, 8, 1.0]])
    base.index.name = 'ID'

    if sign:
        if mu < 0:
            sign='neg'
        else:
            sign='pos'
    else:
        sign=None

    init = gen_init_states(base, column, mu, sigma, amount, sign)

    init.to_csv('DA/input/TA15_input')

if __name__ == '__main__':
    main()
